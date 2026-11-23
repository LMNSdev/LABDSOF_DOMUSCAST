"""US-24: rever, editar e aprovar a ata.

A ata nasce na US-10 (ainda por implementar), por isso estes testes criam-na
diretamente na base de dados, no estado em que o Worker a deixaria.

Critérios de aceitação:
1. Editar o texto do rascunho e consultar a transcrição.
2. A ata só é publicada depois de aprovada; uma resposta tardia da IA nunca a substitui.
3. A ata regista qual o administrador que a aprovou.
4. Após a aprovação apagam-se áudio, transcrição e rascunho.
"""

import logging
from datetime import datetime, timedelta, timezone
from pathlib import Path
from uuid import uuid4

import pytest
from sqlalchemy.exc import OperationalError

from app import atas as atas_dominio
from app import models
from app.routers import atas as atas_router
from app.security import hash_token

TRANSCRICAO = "Ana: proponho reparar a entrada. Rui: concordo. Votação: aprovado por todos."
RASCUNHO = "Decisão: reparar a entrada. Prazo: por confirmar."
EDITADO = "Decisão: reparar a entrada até 31 de dezembro."

CAMPOS_ADMIN = {
    "id",
    "reuniao_id",
    "estado",
    "transcricao",
    "rascunho",
    "texto_aprovado",
    "aprovada_em",
    "aprovada_por",
}
CAMPOS_PUBLICOS = {"reuniao_id", "texto_aprovado", "aprovada_em"}
# Limite provisório da DoR (por confirmar pela equipa). Escrito à mão de propósito:
# mudar o limite em `schemas.py` tem de obrigar a mudar também este teste.
LIMITE_TEXTO = 20_000


# --- Dados de teste --------------------------------------------------------


def _condominio(db):
    condominio = models.Condominio(nome=f"Condomínio {uuid4().hex}", n_fracoes=1)
    db.add(condominio)
    db.flush()
    return condominio


def _admin(db, condominio, nome="Ana"):
    token = uuid4().hex
    admin = models.Administrador(
        condominio_id=condominio.id, nome=nome, credencial_hash=hash_token(token)
    )
    db.add(admin)
    db.commit()
    return admin, token


def _residente(db, condominio):
    fracao = models.Fracao(condominio_id=condominio.id, designacao="A")
    db.add(fracao)
    db.flush()
    token = uuid4().hex
    db.add(models.Identidade(fracao_id=fracao.id, nome="Rui", credencial_hash=hash_token(token)))
    db.commit()
    return token


def _reuniao(db, condominio):
    reuniao = models.Reuniao(
        condominio_id=condominio.id,
        data_hora=datetime.now(timezone.utc) - timedelta(days=1),
        local="Sala do condomínio",
    )
    db.add(reuniao)
    db.commit()
    return reuniao


def _ata(
    db,
    reuniao,
    estado=models.EstadoAta.pendente_revisao,
    transcricao=TRANSCRICAO,
    rascunho=RASCUNHO,
    audio_path="atas/assembleia.m4a",
    origem=models.OrigemAta.ia,
    **extra,
):
    """Uma ata tal como a US-10 a deixaria (por omissão, pronta para revisão)."""
    ata = models.Ata(
        reuniao_id=reuniao.id,
        estado=estado,
        origem=origem,
        transcricao=transcricao,
        rascunho=rascunho,
        audio_path=audio_path,
        **extra,
    )
    db.add(ata)
    db.commit()
    return ata


@pytest.fixture
def cenario(db):
    """Condomínio com administrador, residente e uma reunião ainda sem ata."""
    condominio = _condominio(db)
    admin, token_admin = _admin(db, condominio)
    token_residente = _residente(db, condominio)
    reuniao = _reuniao(db, condominio)

    class Cenario:
        pass

    c = Cenario()
    c.condominio, c.admin, c.reuniao = condominio, admin, reuniao
    c.token_admin, c.token_residente = token_admin, token_residente
    return c


@pytest.fixture
def media(tmp_path, monkeypatch):
    """MEDIA_ROOT temporário, com o ficheiro de áudio que a US-10 teria guardado."""
    raiz = tmp_path / "media"
    (raiz / "atas").mkdir(parents=True)
    (raiz / "atas" / "assembleia.m4a").write_bytes(b"audio")
    monkeypatch.setattr(atas_dominio, "MEDIA_ROOT", raiz)
    return raiz


def _auth(token):
    return {"Authorization": f"Bearer {token}"}


def _get(client, reuniao_id, token):
    return client.get(f"/reunioes/{reuniao_id}/ata", headers=_auth(token))


def _put(client, reuniao_id, token, rascunho=EDITADO):
    return client.put(
        f"/reunioes/{reuniao_id}/ata", headers=_auth(token), json={"rascunho": rascunho}
    )


def _aprovar(client, reuniao_id, token):
    return client.post(f"/reunioes/{reuniao_id}/ata/aprovar", headers=_auth(token))


def _lida(db, ata):
    """A ata como está gravada (sem valores em cache na sessão)."""
    db.expire_all()
    return db.get(models.Ata, ata.id)


def _ata_da(db, reuniao):
    return db.query(models.Ata).filter_by(reuniao_id=reuniao.id).one()


def _falhar_commit(db, monkeypatch):
    def falhar():
        raise OperationalError("COMMIT", {}, Exception("ligação perdida"))

    monkeypatch.setattr(db, "commit", falhar)


# --- GET /reunioes/{id}/ata (só o que a US-24 precisa; o resto é da US-10) ----


def test_admin_consulta_transcricao_e_rascunho(client, db, cenario):
    _ata(db, cenario.reuniao)

    resposta = _get(client, cenario.reuniao.id, cenario.token_admin)

    assert resposta.status_code == 200
    dados = resposta.json()
    assert set(dados) == CAMPOS_ADMIN
    assert dados["reuniao_id"] == cenario.reuniao.id
    assert dados["estado"] == "pendente_revisao"
    assert dados["transcricao"] == TRANSCRICAO
    assert dados["rascunho"] == RASCUNHO
    assert dados["texto_aprovado"] is None
    assert dados["aprovada_em"] is None
    assert dados["aprovada_por"] is None


def test_residente_nao_ve_o_rascunho_por_aprovar(client, db, cenario):
    _ata(db, cenario.reuniao)

    resposta = _get(client, cenario.reuniao.id, cenario.token_residente)

    assert resposta.status_code == 404
    assert resposta.json()["codigo"] == "ata_inexistente"
    # Nem o rascunho nem a transcrição aparecem em lado nenhum da resposta.
    assert RASCUNHO not in resposta.text
    assert TRANSCRICAO not in resposta.text


# --- Autenticação ----------------------------------------------------------

@pytest.mark.parametrize(
    ("metodo", "sufixo", "corpo"),
    [
        ("put", "", {"rascunho": EDITADO}),
        ("post", "/aprovar", None),
    ],
)
@pytest.mark.parametrize("cabecalho", [None, "Bearer credencial-que-nao-existe"])
def test_sem_credencial_valida_devolve_401(client, db, cenario, metodo, sufixo, corpo, cabecalho):
    ata = _ata(db, cenario.reuniao)
    headers = {"Authorization": cabecalho} if cabecalho else {}

    resposta = client.request(
        metodo, f"/reunioes/{cenario.reuniao.id}/ata{sufixo}", headers=headers, json=corpo
    )

    assert resposta.status_code == 401
    assert resposta.json()["codigo"] == "nao_autenticado"
    assert _lida(db, ata).estado == models.EstadoAta.pendente_revisao


def test_administrador_removido_recebe_401(client, db, cenario):
    _ata(db, cenario.reuniao)
    cenario.admin.removido_em = datetime.now(timezone.utc)
    db.commit()

    assert _put(client, cenario.reuniao.id, cenario.token_admin).status_code == 401
    assert _aprovar(client, cenario.reuniao.id, cenario.token_admin).status_code == 401


# --- PUT /reunioes/{id}/ata ------------------------------------------------


def test_admin_edita_o_rascunho_sem_o_publicar(client, db, cenario):
    ata = _ata(db, cenario.reuniao)

    resposta = _put(client, cenario.reuniao.id, cenario.token_admin)

    assert resposta.status_code == 200
    dados = resposta.json()
    assert set(dados) == CAMPOS_ADMIN
    assert dados["rascunho"] == EDITADO
    assert dados["estado"] == "pendente_revisao"
    assert dados["texto_aprovado"] is None
    gravada = _lida(db, ata)
    assert gravada.rascunho == EDITADO
    assert gravada.transcricao == TRANSCRICAO  # continua disponível para consulta
    assert gravada.audio_path == "atas/assembleia.m4a"
    assert gravada.texto_aprovado is None


def test_rascunho_editado_continua_invisivel_ao_residente(client, db, cenario):
    _ata(db, cenario.reuniao)
    _put(client, cenario.reuniao.id, cenario.token_admin)

    resposta = _get(client, cenario.reuniao.id, cenario.token_residente)

    assert resposta.status_code == 404
    assert EDITADO not in resposta.text


def test_editar_varias_vezes_guarda_a_ultima_versao(client, db, cenario):
    ata = _ata(db, cenario.reuniao)

    _put(client, cenario.reuniao.id, cenario.token_admin, "Versão 1")
    _put(client, cenario.reuniao.id, cenario.token_admin, "Versão 2")

    assert _lida(db, ata).rascunho == "Versão 2"


def test_rascunho_e_guardado_sem_espacos_nas_pontas_e_com_quebras_de_linha(client, db, cenario):
    ata = _ata(db, cenario.reuniao)

    _put(client, cenario.reuniao.id, cenario.token_admin, "  \nLinha 1\n\nLinha 2\n  ")

    assert _lida(db, ata).rascunho == "Linha 1\n\nLinha 2"


def test_rascunho_com_o_limite_exato_e_aceite(client, db, cenario):
    ata = _ata(db, cenario.reuniao)
    texto = "á" * LIMITE_TEXTO  # caracteres, não bytes

    resposta = _put(client, cenario.reuniao.id, cenario.token_admin, texto)

    assert resposta.status_code == 200
    assert _lida(db, ata).rascunho == texto


@pytest.mark.parametrize(
    "corpo",
    [
        {"rascunho": ""},
        {"rascunho": "   \n  "},
        {"rascunho": "x" * (LIMITE_TEXTO + 1)},
        {"rascunho": None},
        {"rascunho": 123},
        {},
        {"rascunho": EDITADO, "estado": "aprovada"},  # campos extra são recusados
        {"rascunho": EDITADO, "texto_aprovado": "publicar já"},
    ],
)
def test_rascunho_invalido_devolve_422_e_nao_altera_a_ata(client, db, cenario, corpo):
    ata = _ata(db, cenario.reuniao)

    resposta = client.put(
        f"/reunioes/{cenario.reuniao.id}/ata", headers=_auth(cenario.token_admin), json=corpo
    )

    assert resposta.status_code == 422
    assert resposta.json()["codigo"] == "dados_invalidos"
    gravada = _lida(db, ata)
    assert gravada.rascunho == RASCUNHO
    assert gravada.estado == models.EstadoAta.pendente_revisao


def test_residente_nao_pode_editar(client, db, cenario):
    ata = _ata(db, cenario.reuniao)

    resposta = _put(client, cenario.reuniao.id, cenario.token_residente)

    assert resposta.status_code == 403
    assert resposta.json()["codigo"] == "sem_permissao"
    assert _lida(db, ata).rascunho == RASCUNHO


def test_editar_ata_de_outro_condominio_devolve_404(client, db, cenario):
    reuniao_alheia = _reuniao(db, _condominio(db))
    ata_alheia = _ata(db, reuniao_alheia)

    resposta = _put(client, reuniao_alheia.id, cenario.token_admin)

    assert resposta.status_code == 404
    assert resposta.json()["codigo"] == "reuniao_nao_encontrada"
    assert _lida(db, ata_alheia).rascunho == RASCUNHO


def test_editar_reuniao_sem_ata_devolve_404(client, cenario):
    resposta = _put(client, cenario.reuniao.id, cenario.token_admin)

    assert resposta.status_code == 404
    assert resposta.json()["codigo"] == "ata_inexistente"


@pytest.mark.parametrize(
    ("estado", "codigo"),
    [
        (models.EstadoAta.aprovada, "ata_ja_aprovada"),
        (models.EstadoAta.a_transcrever, "ata_em_processamento"),
        (models.EstadoAta.falhou_transcricao, "ata_sem_rascunho"),
    ],
)
def test_editar_fora_de_revisao_devolve_409(client, db, cenario, estado, codigo):
    ata = _ata(db, cenario.reuniao, estado=estado, rascunho=None, texto_aprovado=None)

    resposta = _put(client, cenario.reuniao.id, cenario.token_admin)

    assert resposta.status_code == 409
    assert resposta.json()["codigo"] == codigo
    gravada = _lida(db, ata)
    assert gravada.estado == estado
    assert gravada.rascunho is None


def test_editar_depois_de_aprovar_nao_altera_o_texto_publicado(client, db, cenario):
    ata = _ata(db, cenario.reuniao)
    _aprovar(client, cenario.reuniao.id, cenario.token_admin)

    resposta = _put(client, cenario.reuniao.id, cenario.token_admin, "Outra versão")

    assert resposta.status_code == 409
    assert resposta.json()["codigo"] == "ata_ja_aprovada"
    gravada = _lida(db, ata)
    assert gravada.texto_aprovado == RASCUNHO
    assert gravada.rascunho is None


def test_ata_aprovada_entre_a_leitura_e_a_escrita_nao_volta_a_ter_rascunho(
    client, db, cenario, monkeypatch
):
    """Corrida: outro pedido aprova a ata depois de o PUT a ler e antes de escrever."""
    ata = _ata(db, cenario.reuniao)
    ler = atas_router._ata_do_admin

    def ler_e_aprovar_noutro_pedido(*args):
        lida = ler(*args)
        db.query(models.Ata).filter_by(id=lida.id).update(
            {"estado": models.EstadoAta.aprovada, "texto_aprovado": RASCUNHO, "rascunho": None},
            synchronize_session=False,
        )
        db.commit()
        return lida

    monkeypatch.setattr(atas_router, "_ata_do_admin", ler_e_aprovar_noutro_pedido)

    resposta = _put(client, cenario.reuniao.id, cenario.token_admin)

    assert resposta.status_code == 409
    assert resposta.json()["codigo"] == "ata_ja_aprovada"
    gravada = _lida(db, ata)
    assert gravada.rascunho is None
    assert gravada.texto_aprovado == RASCUNHO


def test_put_base_de_dados_indisponivel_devolve_503_e_nao_altera(client, db, cenario, monkeypatch):
    ata = _ata(db, cenario.reuniao)
    _falhar_commit(db, monkeypatch)

    resposta = _put(client, cenario.reuniao.id, cenario.token_admin)

    assert resposta.status_code == 503
    assert resposta.json()["codigo"] == "servico_indisponivel"
    monkeypatch.undo()
    assert _lida(db, ata).rascunho == RASCUNHO


# --- POST /reunioes/{id}/ata/aprovar ---------------------------------------


def test_aprovar_publica_o_rascunho_e_regista_quem_aprovou(client, db, cenario, media):
    ata = _ata(db, cenario.reuniao)
    antes = datetime.now(timezone.utc)

    resposta = _aprovar(client, cenario.reuniao.id, cenario.token_admin)

    assert resposta.status_code == 200
    dados = resposta.json()
    assert set(dados) == CAMPOS_ADMIN
    assert dados["estado"] == "aprovada"
    assert dados["texto_aprovado"] == RASCUNHO
    assert dados["aprovada_por"] == cenario.admin.id
    aprovada_em = datetime.fromisoformat(dados["aprovada_em"])
    assert antes - timedelta(seconds=1) <= aprovada_em <= datetime.now(timezone.utc)
    gravada = _lida(db, ata)
    assert gravada.estado == models.EstadoAta.aprovada
    assert gravada.texto_aprovado == RASCUNHO
    assert gravada.aprovada_por == cenario.admin.id
    assert gravada.aprovada_em is not None


def test_aprovar_apaga_audio_transcricao_e_rascunho(client, db, cenario, media):
    ata = _ata(db, cenario.reuniao)
    ficheiro = media / "atas" / "assembleia.m4a"
    assert ficheiro.exists()

    resposta = _aprovar(client, cenario.reuniao.id, cenario.token_admin)

    assert resposta.status_code == 200
    assert resposta.json()["transcricao"] is None
    assert resposta.json()["rascunho"] is None
    gravada = _lida(db, ata)
    assert gravada.transcricao is None
    assert gravada.rascunho is None
    assert gravada.audio_path is None
    assert not ficheiro.exists()


def test_editar_e_aprovar_publica_o_texto_editado_ao_residente(client, db, cenario, media):
    _ata(db, cenario.reuniao)

    assert _put(client, cenario.reuniao.id, cenario.token_admin).status_code == 200
    assert _aprovar(client, cenario.reuniao.id, cenario.token_admin).status_code == 200
    resposta = _get(client, cenario.reuniao.id, cenario.token_residente)

    assert resposta.status_code == 200
    assert set(resposta.json()) == CAMPOS_PUBLICOS  # sem transcrição, rascunho nem quem aprovou
    assert resposta.json()["texto_aprovado"] == EDITADO
    assert RASCUNHO not in resposta.text


def test_aprovacao_regista_o_administrador_que_aprovou_e_nao_outro(client, db, cenario, media):
    """Com dois administradores (US-19), fica registado o que fez o pedido."""
    segundo, token_segundo = _admin(db, cenario.condominio, nome="Rita")
    ata = _ata(db, cenario.reuniao)

    _aprovar(client, cenario.reuniao.id, token_segundo)

    assert _lida(db, ata).aprovada_por == segundo.id


def test_aprovar_duas_vezes_devolve_409_e_mantem_a_primeira(client, db, cenario, media):
    segundo, token_segundo = _admin(db, cenario.condominio, nome="Rita")
    ata = _ata(db, cenario.reuniao)
    primeira = _aprovar(client, cenario.reuniao.id, cenario.token_admin).json()

    resposta = _aprovar(client, cenario.reuniao.id, token_segundo)

    assert resposta.status_code == 409
    assert resposta.json()["codigo"] == "ata_ja_aprovada"
    gravada = _lida(db, ata)
    assert gravada.aprovada_por == cenario.admin.id
    assert gravada.texto_aprovado == primeira["texto_aprovado"]


def test_aprovacao_em_simultaneo_so_a_primeira_conta(client, db, cenario, media, monkeypatch):
    """Corrida: outro administrador aprova depois de este pedido ler a ata."""
    segundo, _ = _admin(db, cenario.condominio, nome="Rita")
    ata = _ata(db, cenario.reuniao)
    ler = atas_router._ata_do_admin

    def ler_e_aprovar_noutro_pedido(*args):
        lida = ler(*args)
        db.query(models.Ata).filter_by(id=lida.id).update(
            {
                "estado": models.EstadoAta.aprovada,
                "texto_aprovado": "Texto do outro administrador",
                "rascunho": None,
                "aprovada_por": segundo.id,
            },
            synchronize_session=False,
        )
        db.commit()
        return lida

    monkeypatch.setattr(atas_router, "_ata_do_admin", ler_e_aprovar_noutro_pedido)

    resposta = _aprovar(client, cenario.reuniao.id, cenario.token_admin)

    assert resposta.status_code == 409
    assert resposta.json()["codigo"] == "ata_ja_aprovada"
    gravada = _lida(db, ata)
    assert gravada.aprovada_por == segundo.id
    assert gravada.texto_aprovado == "Texto do outro administrador"


@pytest.mark.parametrize(
    ("estado", "rascunho", "codigo"),
    [
        (models.EstadoAta.a_transcrever, None, "ata_em_processamento"),
        (models.EstadoAta.falhou_transcricao, None, "ata_sem_rascunho"),
        (models.EstadoAta.pendente_revisao, None, "ata_sem_rascunho"),
        (models.EstadoAta.pendente_revisao, "", "ata_sem_rascunho"),
        (models.EstadoAta.pendente_revisao, "   ", "ata_sem_rascunho"),
        # Com um rascunho antigo ainda gravado (ex.: áudio reenviado), o estado decide.
        (models.EstadoAta.a_transcrever, RASCUNHO, "ata_em_processamento"),
        (models.EstadoAta.falhou_transcricao, RASCUNHO, "ata_sem_rascunho"),
    ],
)
def test_aprovar_sem_rascunho_pronto_devolve_409_e_preserva_o_audio(
    client, db, cenario, media, estado, rascunho, codigo
):
    ata = _ata(db, cenario.reuniao, estado=estado, rascunho=rascunho)

    resposta = _aprovar(client, cenario.reuniao.id, cenario.token_admin)

    assert resposta.status_code == 409
    assert resposta.json()["codigo"] == codigo
    gravada = _lida(db, ata)
    assert gravada.estado == estado
    assert gravada.texto_aprovado is None
    assert gravada.aprovada_por is None
    assert gravada.audio_path == "atas/assembleia.m4a"
    assert (media / "atas" / "assembleia.m4a").exists()


def test_ata_aprovada_com_rascunho_residual_nao_e_reaprovada(client, db, cenario, media):
    ata = _ata(
        db,
        cenario.reuniao,
        estado=models.EstadoAta.aprovada,
        texto_aprovado=EDITADO,
        aprovada_por=cenario.admin.id,
    )
    segundo, token_segundo = _admin(db, cenario.condominio, nome="Rita")

    resposta = _aprovar(client, cenario.reuniao.id, token_segundo)

    assert resposta.status_code == 409
    assert resposta.json()["codigo"] == "ata_ja_aprovada"
    gravada = _lida(db, ata)
    assert gravada.texto_aprovado == EDITADO
    assert gravada.aprovada_por == cenario.admin.id


def test_residente_nao_pode_aprovar(client, db, cenario, media):
    ata = _ata(db, cenario.reuniao)

    resposta = _aprovar(client, cenario.reuniao.id, cenario.token_residente)

    assert resposta.status_code == 403
    assert resposta.json()["codigo"] == "sem_permissao"
    assert _lida(db, ata).estado == models.EstadoAta.pendente_revisao
    assert (media / "atas" / "assembleia.m4a").exists()


def test_aprovar_ata_de_outro_condominio_devolve_404(client, db, cenario, media):
    reuniao_alheia = _reuniao(db, _condominio(db))
    ata_alheia = _ata(db, reuniao_alheia)

    resposta = _aprovar(client, reuniao_alheia.id, cenario.token_admin)

    assert resposta.status_code == 404
    assert resposta.json()["codigo"] == "reuniao_nao_encontrada"
    assert _lida(db, ata_alheia).estado == models.EstadoAta.pendente_revisao
    assert (media / "atas" / "assembleia.m4a").exists()


def test_aprovar_reuniao_sem_ata_devolve_404(client, cenario):
    resposta = _aprovar(client, cenario.reuniao.id, cenario.token_admin)

    assert resposta.status_code == 404
    assert resposta.json()["codigo"] == "ata_inexistente"


def test_aprovar_ignora_corpo_do_pedido(client, db, cenario, media):
    """O texto publicado é sempre o rascunho guardado, nunca um texto enviado à parte."""
    ata = _ata(db, cenario.reuniao)

    resposta = client.post(
        f"/reunioes/{cenario.reuniao.id}/ata/aprovar",
        headers=_auth(cenario.token_admin),
        json={"texto_aprovado": "Texto nunca revisto"},
    )

    assert resposta.status_code == 200
    assert _lida(db, ata).texto_aprovado == RASCUNHO


def test_aprovar_falha_na_base_de_dados_devolve_503_e_preserva_tudo(
    client, db, cenario, media, monkeypatch
):
    ata = _ata(db, cenario.reuniao)
    _falhar_commit(db, monkeypatch)

    resposta = _aprovar(client, cenario.reuniao.id, cenario.token_admin)

    assert resposta.status_code == 503
    assert resposta.json()["codigo"] == "servico_indisponivel"
    monkeypatch.undo()
    gravada = _lida(db, ata)
    assert gravada.estado == models.EstadoAta.pendente_revisao
    assert gravada.rascunho == RASCUNHO
    assert gravada.transcricao == TRANSCRICAO
    assert gravada.texto_aprovado is None
    assert (media / "atas" / "assembleia.m4a").exists()


# --- Ficheiro de áudio (segurança e privacidade da eliminação) --------------


def test_falha_a_apagar_o_audio_nao_desfaz_a_aprovacao_nem_expoe_o_caminho(
    client, db, cenario, media, monkeypatch, caplog
):
    ata = _ata(db, cenario.reuniao)

    def falhar(caminho, *_args, **_kwargs):
        # Como um OSError real: a mensagem inclui o caminho do ficheiro.
        raise PermissionError(13, "Permission denied", str(caminho))

    monkeypatch.setattr(Path, "unlink", falhar)

    with caplog.at_level(logging.DEBUG, logger="app.atas"):
        resposta = _aprovar(client, cenario.reuniao.id, cenario.token_admin)

    assert resposta.status_code == 200
    assert _lida(db, ata).estado == models.EstadoAta.aprovada
    assert "apagar o áudio" in caplog.text
    assert "assembleia.m4a" not in caplog.text  # sem o caminho no log (RNF-08)


@pytest.mark.parametrize("caminho", ["../fora.m4a", "atas/../../fora.m4a", "ABSOLUTO"])
def test_audio_fora_de_media_root_nunca_e_apagado(client, db, cenario, media, caminho):
    fora = media.parent / "fora.m4a"
    fora.write_bytes(b"nao apagar")
    _ata(db, cenario.reuniao, audio_path=str(fora) if caminho == "ABSOLUTO" else caminho)

    resposta = _aprovar(client, cenario.reuniao.id, cenario.token_admin)

    assert resposta.status_code == 200
    assert _lida(db, _ata_da(db, cenario.reuniao)).estado == models.EstadoAta.aprovada
    assert fora.exists()


# ---------------------------------------------------------------------------
# Resposta tardia do Worker (critério 2): gravar_resultado_ia
# ---------------------------------------------------------------------------


def test_resultado_da_ia_preenche_ata_a_transcrever(db, cenario):
    ata = _ata(db, cenario.reuniao, estado=models.EstadoAta.a_transcrever, transcricao=None, rascunho=None)

    gravou = atas_dominio.gravar_resultado_ia(db, ata.id, TRANSCRICAO, RASCUNHO)
    db.commit()

    assert gravou is True
    gravada = _lida(db, ata)
    assert gravada.estado == models.EstadoAta.pendente_revisao
    assert gravada.transcricao == TRANSCRICAO
    assert gravada.rascunho == RASCUNHO


def test_resposta_tardia_da_ia_nao_substitui_ata_aprovada(client, db, cenario, media):
    ata = _ata(db, cenario.reuniao)
    _put(client, cenario.reuniao.id, cenario.token_admin)
    _aprovar(client, cenario.reuniao.id, cenario.token_admin)

    gravou = atas_dominio.gravar_resultado_ia(db, ata.id, "Transcrição tardia", "Rascunho tardio")
    db.commit()

    assert gravou is False
    gravada = _lida(db, ata)
    assert gravada.estado == models.EstadoAta.aprovada
    assert gravada.texto_aprovado == EDITADO
    assert gravada.rascunho is None
    assert gravada.transcricao is None
    resposta = _get(client, cenario.reuniao.id, cenario.token_residente)
    assert resposta.json()["texto_aprovado"] == EDITADO


def test_resposta_tardia_da_ia_nao_apaga_a_edicao_do_administrador(client, db, cenario):
    ata = _ata(db, cenario.reuniao)
    _put(client, cenario.reuniao.id, cenario.token_admin)

    gravou = atas_dominio.gravar_resultado_ia(db, ata.id, "Transcrição tardia", "Rascunho tardio")
    db.commit()

    assert gravou is False
    gravada = _lida(db, ata)
    assert gravada.rascunho == EDITADO
    assert gravada.transcricao == TRANSCRICAO


def test_resultado_da_ia_ignorado_numa_ata_falhada(db, cenario):
    ata = _ata(
        db, cenario.reuniao, estado=models.EstadoAta.falhou_transcricao, transcricao=None, rascunho=None
    )

    assert atas_dominio.gravar_resultado_ia(db, ata.id, TRANSCRICAO, RASCUNHO) is False
    db.commit()
    assert _lida(db, ata).estado == models.EstadoAta.falhou_transcricao


def test_resultado_da_ia_para_ata_inexistente_e_ignorado(db):
    assert atas_dominio.gravar_resultado_ia(db, 999_999, TRANSCRICAO, RASCUNHO) is False


# ---------------------------------------------------------------------------
# Modelo de dados (migrações 0008 e 0009)
# ---------------------------------------------------------------------------


def test_uma_reuniao_so_pode_ter_uma_ata(db, cenario):
    from sqlalchemy.exc import IntegrityError

    _ata(db, cenario.reuniao)
    db.add(
        models.Ata(
            reuniao_id=cenario.reuniao.id,
            estado=models.EstadoAta.a_transcrever,
            origem=models.OrigemAta.ia,
        )
    )

    with pytest.raises(IntegrityError):
        db.commit()
    db.rollback()


def test_ata_sem_estado_e_recusada(db, cenario):
    from sqlalchemy.exc import IntegrityError

    db.add(models.Ata(reuniao_id=cenario.reuniao.id, origem=models.OrigemAta.ia))

    with pytest.raises(IntegrityError):
        db.commit()
    db.rollback()


def test_ata_sem_origem_e_recusada(db, cenario):
    """Migração 0009: quem cria a ata (US-10 ou US-25) indica sempre a origem."""
    from sqlalchemy.exc import IntegrityError

    db.add(models.Ata(reuniao_id=cenario.reuniao.id, estado=models.EstadoAta.a_transcrever))

    with pytest.raises(IntegrityError):
        db.commit()
    db.rollback()
