import io
from datetime import datetime, timezone
from uuid import uuid4

import pytest
from PIL import Image

from app import models, rate_limit
from app.routers import reportes as reportes_router
from app.security import hash_token


@pytest.fixture(autouse=True)
def limpar_rate_limit():
    rate_limit.reset()
    yield
    rate_limit.reset()


def _criar_residente(db, nome="Residente", token=None):
    token = token or uuid4().hex
    condominio = models.Condominio(nome=f"Condomínio {uuid4().hex}", n_fracoes=1)
    db.add(condominio)
    db.flush()
    fracao = models.Fracao(condominio_id=condominio.id, designacao="A")
    db.add(fracao)
    db.flush()
    identidade = models.Identidade(
        fracao_id=fracao.id,
        nome=nome,
        credencial_hash=hash_token(token),
    )
    db.add(identidade)
    db.commit()
    db.refresh(identidade)
    return identidade, token


def _form(descricao="Avaria no prédio", **campos):
    return {
        "descricao": (None, descricao),
        **{nome: (None, valor) for nome, valor in campos.items()},
    }


def _headers(token, chave="idem-key"):
    return {
        "Authorization": f"Bearer {token}",
        "Idempotency-Key": chave,
    }


def _imagem(formato="JPEG", exif=False):
    imagem = Image.new("RGB", (4, 4), color="red")
    buffer = io.BytesIO()
    if exif:
        metadados = Image.Exif()
        metadados[0x010E] = "dados pessoais"
        imagem.save(buffer, format=formato, exif=metadados)
    else:
        imagem.save(buffer, format=formato)
    return buffer.getvalue()


def test_criar_reporte_sem_foto(client, db):
    identidade, token = _criar_residente(db)

    resposta = client.post(
        "/reportes",
        headers=_headers(token),
        files=_form("  Torneira com fuga  ", mostrar_nome="false"),
    )

    assert resposta.status_code == 201
    assert resposta.headers["X-Request-ID"]
    dados = resposta.json()
    assert dados["descricao"] == "Torneira com fuga"
    assert dados["estado"] == "aberto"
    reporte = db.query(models.Reporte).filter_by(id=dados["id"]).one()
    assert reporte.autor_id == identidade.id
    assert reporte.condominio_id == identidade.fracao.condominio_id
    assert reporte.foto_path is None
    assert reporte.mostrar_nome is False


def test_criar_reporte_com_nome_visivel(client, db):
    _, token = _criar_residente(db)

    resposta = client.post(
        "/reportes",
        headers=_headers(token),
        files=_form("Fuga", mostrar_nome="true"),
    )

    assert resposta.status_code == 201
    reporte = db.query(models.Reporte).filter_by(id=resposta.json()["id"]).one()
    assert reporte.mostrar_nome is True


def test_criar_reporte_com_foto_e_remover_exif(client, db, tmp_path, monkeypatch):
    identidade, token = _criar_residente(db)
    monkeypatch.setattr(reportes_router, "MEDIA_ROOT", tmp_path)

    resposta = client.post(
        "/reportes",
        headers=_headers(token),
        files={
            **_form("Fuga de água", foto_alt="Poça no chão"),
            "foto": ("fuga.jpg", _imagem(exif=True), "image/jpeg"),
        },
    )

    assert resposta.status_code == 201
    reporte = db.query(models.Reporte).filter_by(id=resposta.json()["id"]).one()
    assert reporte.autor_id == identidade.id
    assert reporte.foto_alt == "Poça no chão"
    imagem_guardada = Image.open(tmp_path / reporte.foto_path)
    assert imagem_guardada.format == "JPEG"
    assert not imagem_guardada.getexif()


def test_foto_png_e_aceite(client, db, tmp_path, monkeypatch):
    _, token = _criar_residente(db)
    monkeypatch.setattr(reportes_router, "MEDIA_ROOT", tmp_path)

    resposta = client.post(
        "/reportes",
        headers=_headers(token),
        files={
            **_form("Fuga", foto_alt="Poça no chão"),
            "foto": ("fuga.png", _imagem("PNG"), "image/png"),
        },
    )

    assert resposta.status_code == 201
    reporte = db.query(models.Reporte).filter_by(id=resposta.json()["id"]).one()
    assert reporte.foto_path.endswith(".png")


def test_foto_sem_texto_alternativo_e_rejeitada(client, db):
    _, token = _criar_residente(db)

    resposta = client.post(
        "/reportes",
        headers=_headers(token),
        files={"descricao": (None, "Fuga"), "foto": ("fuga.jpg", _imagem())},
    )

    assert resposta.status_code == 422
    assert resposta.json()["codigo"] == "dados_invalidos"


def test_foto_com_formato_nao_suportado_e_rejeitada(client, db):
    _, token = _criar_residente(db)

    resposta = client.post(
        "/reportes",
        headers=_headers(token),
        files={
            **_form("Fuga", foto_alt="Imagem"),
            "foto": ("foto.gif", _imagem("GIF"), "image/gif"),
        },
    )

    assert resposta.status_code == 422


def test_foto_acima_de_5_mb_e_rejeitada(client, db):
    _, token = _criar_residente(db)

    resposta = client.post(
        "/reportes",
        headers=_headers(token),
        files={
            **_form("Fuga", foto_alt="Imagem"),
            "foto": ("foto.jpg", b"x" * (5 * 1024 * 1024 + 1), "image/jpeg"),
        },
    )

    assert resposta.status_code == 422


@pytest.mark.parametrize("campo", ["telefone", "email", "perfil"])
def test_campos_de_contacto_sao_rejeitados(client, db, campo):
    _, token = _criar_residente(db)

    resposta = client.post(
        "/reportes",
        headers=_headers(token),
        files={**_form("Fuga"), campo: (None, "dado pessoal")},
    )

    assert resposta.status_code == 422
    assert resposta.json()["codigo"] == "dados_invalidos"


def test_descricao_vazia_e_rejeitada(client, db):
    _, token = _criar_residente(db)

    resposta = client.post(
        "/reportes",
        headers=_headers(token),
        files=_form("   "),
    )

    assert resposta.status_code == 422
    assert resposta.json()["codigo"] == "dados_invalidos"


def test_descricao_acima_de_2000_caracteres_e_rejeitada(client, db):
    _, token = _criar_residente(db)

    resposta = client.post(
        "/reportes",
        headers=_headers(token),
        files=_form("x" * 2001),
    )

    assert resposta.status_code == 422
    assert resposta.json()["codigo"] == "dados_invalidos"


def test_pedido_tem_de_ser_multipart(client, db):
    _, token = _criar_residente(db)

    resposta = client.post(
        "/reportes",
        headers=_headers(token),
        json={"descricao": "Fuga"},
    )

    assert resposta.status_code == 422
    assert resposta.json()["codigo"] == "dados_invalidos"


def test_reenvio_com_mesma_chave_devolve_reporte_existente(client, db):
    identidade, token = _criar_residente(db)
    headers = _headers(token, "reenvio-1")

    primeira = client.post("/reportes", headers=headers, files=_form("Fuga"))
    segunda = client.post(
        "/reportes", headers=headers, files=_form("Conteúdo diferente")
    )

    assert primeira.status_code == 201
    assert segunda.status_code == 200
    assert primeira.json()["id"] == segunda.json()["id"]
    assert segunda.json()["descricao"] == "Fuga"
    assert db.query(models.Reporte).filter_by(autor_id=identidade.id).count() == 1


def test_chave_de_idempotencia_e_isolada_por_autor(client, db):
    _, token_a = _criar_residente(db, "Residente A")
    _, token_b = _criar_residente(db, "Residente B")

    resposta_a = client.post(
        "/reportes", headers=_headers(token_a, "mesma-chave"), files=_form("Reporte A")
    )
    resposta_b = client.post(
        "/reportes", headers=_headers(token_b, "mesma-chave"), files=_form("Reporte B")
    )

    assert resposta_a.status_code == 201
    assert resposta_b.status_code == 201
    assert resposta_a.json()["id"] != resposta_b.json()["id"]


def test_residente_sem_credencial_recebe_401(client):
    resposta = client.post(
        "/reportes",
        headers={"Idempotency-Key": "sem-credencial"},
        files=_form("Fuga"),
    )

    assert resposta.status_code == 401
    assert resposta.json()["codigo"] == "nao_autenticado"
    assert resposta.headers["X-Request-ID"] == resposta.json()["request_id"]


def test_credencial_invalida_recebe_401(client):
    resposta = client.post(
        "/reportes",
        headers=_headers("token-invalido"),
        files=_form("Fuga"),
    )

    assert resposta.status_code == 401
    assert resposta.json()["codigo"] == "nao_autenticado"


def test_identidade_removida_recebe_401(client, db):
    identidade, token = _criar_residente(db)
    identidade.removida_em = datetime.now(timezone.utc)
    db.commit()

    resposta = client.post(
        "/reportes",
        headers=_headers(token),
        files=_form("Fuga"),
    )

    assert resposta.status_code == 401
    assert resposta.json()["codigo"] == "nao_autenticado"


def test_chave_de_idempotencia_e_obrigatoria(client, db):
    _, token = _criar_residente(db)

    resposta = client.post(
        "/reportes",
        headers={"Authorization": f"Bearer {token}"},
        files=_form("Fuga"),
    )

    assert resposta.status_code == 422
    assert resposta.json()["codigo"] == "dados_invalidos"


def test_administrador_nao_pode_criar_reporte(client, db):
    token = uuid4().hex
    condominio = models.Condominio(nome=f"Condomínio {uuid4().hex}", n_fracoes=1)
    db.add(condominio)
    db.flush()
    db.add(
        models.Administrador(
            condominio_id=condominio.id,
            nome="Admin",
            credencial_hash=hash_token(token),
        )
    )
    db.commit()

    resposta = client.post("/reportes", headers=_headers(token), files=_form("Fuga"))

    assert resposta.status_code == 403
    assert resposta.json()["codigo"] == "sem_permissao"


def test_listar_reportes(client, db):
    _, token = _criar_residente(db)
    client.post("/reportes", headers=_headers(token), files=_form("Elevador avariado"))

    resposta = client.get("/reportes", headers=_headers(token))

    assert resposta.status_code == 200
    assert isinstance(resposta.json(), list)
    reporte = next(
        reporte
        for reporte in resposta.json()
        if reporte["descricao"] == "Elevador avariado"
    )
    assert reporte["meu"] is True
    assert reporte["autor_nome"] is None
    assert reporte["fracao"] is None


# --- US-09: o que cada papel vê do autor (repostos da main, agora em multipart) ---


def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


def criar_sessao(client, nome="Marta Silva"):
    condominio = client.post(
        "/condominios",
        json={"nome": "Prédio", "nome_admin": "Ana", "n_fracoes": 1},
    ).json()
    fracao = condominio["fracoes"][0]
    admin = condominio["credencial_admin"]
    qr = client.post(
        f"/fracoes/{fracao['id']}/qr",
        headers={"Authorization": f"Bearer {admin}"},
    ).json()
    entrada = client.post(
        "/identidades",
        json={"token": qr["token"], "nome": nome},
    ).json()
    return admin, entrada["credencial"], fracao, qr["token"]


def criar_duas_sessoes_na_mesma_fracao(client):
    admin, credencial_a, fracao, token_qr = criar_sessao(client, "Marta Silva")
    credencial_b = client.post(
        "/identidades",
        json={"token": token_qr, "nome": "Rui Costa"},
    ).json()["credencial"]
    return admin, credencial_a, credencial_b, fracao


def auth(credencial):
    return {"Authorization": f"Bearer {credencial}"}


def reportar(client, credencial, descricao, chave=None, **campos):
    return client.post(
        "/reportes",
        headers=_headers(credencial, chave or uuid4().hex),
        files=_form(descricao, **campos),
    )


def test_criacao_devolve_o_reporte_como_o_autor_o_ve(client):
    _, credencial, _, _ = criar_sessao(client)
    dados = reportar(client, credencial, "Torneira com fuga").json()
    assert dados["meu"] is True
    assert dados["mostrar_nome"] is False
    assert dados["autor_nome"] is None
    assert dados["fracao"] is None


def test_pedidos_simultaneos_do_mesmo_autor_devolvem_o_mesmo_reporte(client, monkeypatch):
    _, credencial, _, _ = criar_sessao(client)
    r1 = reportar(client, credencial, "Fuga", chave="chave-corrida-001")

    # Simula o segundo pedido a chegar antes de o primeiro estar gravado:
    # a primeira procura não o encontra e o commit esbarra no unique.
    real = reportes_router._por_chave
    chamadas = []

    def primeira_procura_falha(db, residente, chave):
        chamadas.append(chave)
        return None if len(chamadas) == 1 else real(db, residente, chave)

    monkeypatch.setattr(reportes_router, "_por_chave", primeira_procura_falha)
    r2 = reportar(client, credencial, "Fuga", chave="chave-corrida-001")
    assert r2.status_code == 200
    assert r2.json()["id"] == r1.json()["id"]
    assert len(chamadas) == 2


def test_residente_sem_mostrar_nome_nao_e_identificado_a_outro_residente(client):
    _, credencial_a, credencial_b, _ = criar_duas_sessoes_na_mesma_fracao(client)
    reportar(client, credencial_a, "Fuga na garagem", mostrar_nome="false")
    resposta = client.get("/reportes", headers=auth(credencial_b))
    assert resposta.status_code == 200
    reporte = next(r for r in resposta.json() if r["descricao"] == "Fuga na garagem")
    assert reporte["autor_nome"] is None
    assert reporte["fracao"] is None
    assert reporte["meu"] is False


def test_residente_com_mostrar_nome_e_identificado_a_outro_residente(client):
    _, credencial_a, credencial_b, _ = criar_duas_sessoes_na_mesma_fracao(client)
    reportar(client, credencial_a, "Escada", mostrar_nome="true")
    resposta = client.get("/reportes", headers=auth(credencial_b))
    reporte = next(r for r in resposta.json() if r["descricao"] == "Escada")
    assert reporte["autor_nome"] == "Marta Silva"
    assert reporte["fracao"] is None


def test_administrador_ve_nome_e_fracao(client):
    admin, credencial, fracao, _ = criar_sessao(client)
    reportar(client, credencial, "Elevador", mostrar_nome="false")
    resposta = client.get("/reportes", headers=auth(admin))
    reporte = next(r for r in resposta.json() if r["descricao"] == "Elevador")
    assert reporte["autor_nome"] == "Marta Silva"
    assert reporte["fracao"] == fracao["designacao"]
    assert reporte["meu"] is False


def test_autor_removido_deixa_de_ser_identificado(client, db):
    admin, credencial_a, credencial_b, _ = criar_duas_sessoes_na_mesma_fracao(client)
    criado = reportar(client, credencial_a, "Garagem", mostrar_nome="true").json()
    autora = db.get(models.Reporte, criado["id"]).autor
    autora.removida_em = datetime.now(timezone.utc)
    db.commit()

    for credencial in (admin, credencial_b):
        reporte = next(
            r for r in client.get("/reportes", headers=auth(credencial)).json()
            if r["id"] == criado["id"]
        )
        assert reporte["autor_nome"] is None
        assert reporte["fracao"] is None


def test_residente_de_outro_condominio_nao_ve_os_reportes(client):
    _, credencial_a, _, _ = criar_sessao(client)
    _, credencial_b, _, _ = criar_sessao(client, nome="Rui Costa")
    reportar(client, credencial_a, "Fuga")
    assert client.get("/reportes", headers=auth(credencial_b)).json() == []


def test_sem_credencial_nao_lista_reportes(client):
    assert client.get("/reportes").status_code == 401


def test_credencial_invalida_nao_lista_reportes(client):
    assert client.get("/reportes", headers=auth("credencial-que-nao-existe")).status_code == 401


def test_identidade_nao_tem_campos_de_contacto():
    colunas = {c.name for c in models.Identidade.__table__.columns}
    assert colunas.isdisjoint({"telefone", "email", "perfil", "contacto"})
