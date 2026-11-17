import io
from datetime import datetime, timezone
from uuid import uuid4

from PIL import Image

from app import models
from app.routers import reportes as reportes_router
from app.security import hash_token


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


def test_campos_de_contacto_sao_rejeitados(client, db):
    _, token = _criar_residente(db)

    resposta = client.post(
        "/reportes",
        headers=_headers(token),
        files={**_form("Fuga"), "telefone": (None, "912345678")},
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

    resposta = client.get("/reportes")

    assert resposta.status_code == 200
    assert isinstance(resposta.json(), list)
    assert any(
        reporte["descricao"] == "Elevador avariado" for reporte in resposta.json()
    )
