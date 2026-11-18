"""US-15: o residente indica o nome no primeiro acesso pelo QR code da fração."""

from datetime import datetime, timezone

import pytest
from fastapi.testclient import TestClient

from app import models, rate_limit
from app.main import app
from app.security import hash_token


@pytest.fixture(autouse=True)
def limpar_rate_limit():
    rate_limit.reset()
    yield
    rate_limit.reset()


def novo_condominio(client, n_fracoes=1):
    return client.post(
        "/condominios", json={"nome": "Prédio", "nome_admin": "Ana", "n_fracoes": n_fracoes}
    ).json()


def gerar_qr(client, condominio, indice=0):
    fracao_id = condominio["fracoes"][indice]["id"]
    headers = {"Authorization": f"Bearer {condominio['credencial_admin']}"}
    return client.post(f"/fracoes/{fracao_id}/qr", headers=headers).json()["token"]


@pytest.fixture
def token(client):
    return gerar_qr(client, novo_condominio(client))


def entrar(client, token, nome):
    return client.post("/identidades", json={"token": token, "nome": nome})


# --- Criar identidade ---------------------------------------------------------


def test_cria_identidade_e_devolve_credencial_e_fracao(client, db, token):
    r = entrar(client, token, "Marta Silva")
    assert r.status_code == 201
    data = r.json()
    assert data["nome"] == "Marta Silva"
    assert data["fracao"] == "A"
    assert len(data["credencial"]) >= 32

    identidade = db.get(models.Identidade, data["id"])
    assert identidade.credencial_hash == hash_token(data["credencial"])
    assert identidade.qr_token_id == db.query(models.QrToken).filter_by(token_hash=hash_token(token)).one().id


@pytest.mark.parametrize("nome", ["", "   "])
def test_nome_vazio_devolve_422(client, token, nome):
    assert entrar(client, token, nome).status_code == 422


def test_nao_aceita_contactos(client, token):
    r = client.post("/identidades", json={"token": token, "nome": "Marta", "telefone": "912345678"})
    assert r.status_code == 422


@pytest.mark.parametrize("repetido", ["Marta Silva", "MARTA SILVA", "Márta  Sílva", " martasilva "])
def test_nome_repetido_na_fracao_devolve_409_nome_duplicado(client, token, repetido):
    assert entrar(client, token, "Marta Silva").status_code == 201
    r = entrar(client, token, repetido)
    assert r.status_code == 409
    assert r.json()["codigo"] == "nome_duplicado"
    assert r.json()["request_id"]


def test_mesmo_nome_noutra_fracao_e_aceite(client):
    condominio = novo_condominio(client, n_fracoes=2)
    assert entrar(client, gerar_qr(client, condominio, 0), "Marta Silva").status_code == 201
    assert entrar(client, gerar_qr(client, condominio, 1), "Marta Silva").status_code == 201


def test_varios_residentes_com_o_mesmo_qr_tem_identidades_distintas(client, token):
    a = entrar(client, token, "Marta Silva").json()
    b = entrar(client, token, "Rui Silva").json()
    assert a["id"] != b["id"]
    assert a["credencial"] != b["credencial"]
    assert a["fracao"] == b["fracao"] == "A"


def test_11a_identidade_da_fracao_devolve_409_fracao_cheia(client):
    condominio = novo_condominio(client)
    tokens = [gerar_qr(client, condominio), gerar_qr(client, condominio)]
    for i in range(10):
        assert entrar(client, tokens[i % 2], f"Residente {i}").status_code == 201
    r = entrar(client, tokens[0], "Residente 10")
    assert r.status_code == 409
    assert r.json()["codigo"] == "fracao_cheia"


def test_token_invalido_e_revogado_tem_a_mesma_resposta_404(client, db, token):
    invalido = entrar(client, "token-inventado", "Marta")

    qr = db.query(models.QrToken).filter_by(token_hash=hash_token(token)).one()
    qr.revogado_em = datetime.now(timezone.utc)
    db.commit()
    revogado = entrar(client, token, "Marta")

    assert invalido.status_code == revogado.status_code == 404
    assert {**invalido.json(), "request_id": None} == {**revogado.json(), "request_id": None}


# --- Limite de tentativas (10.5 e refinamento) --------------------------------


def test_31a_tentativa_no_mesmo_qr_devolve_429_mesmo_de_outro_ip(client, token):
    entrar(client, token, "Marta Silva")
    for _ in range(29):
        entrar(client, token, "Marta Silva")
    outro_ip = TestClient(app, client=("10.0.0.2", 50000))
    assert entrar(outro_ip, token, "Rui Silva").status_code == 429


def test_21a_tentativa_com_token_invalido_no_mesmo_ip_devolve_429(client, token):
    for _ in range(20):
        assert entrar(client, "token-inventado", "Marta").status_code == 404
    assert entrar(client, "token-inventado", "Marta").status_code == 429
    # Um vizinho no mesmo IP com um QR code válido não é afetado.
    assert entrar(client, token, "Marta Silva").status_code == 201


def test_11_vizinhos_no_mesmo_ip_com_qr_validos_nao_recebem_429(client):
    condominio = novo_condominio(client, n_fracoes=11)
    for i in range(11):
        assert entrar(client, gerar_qr(client, condominio, i), "Marta Silva").status_code == 201
