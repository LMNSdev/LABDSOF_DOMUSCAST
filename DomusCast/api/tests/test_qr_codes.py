"""US-20: o administrador lista e revoga os QR codes ativos de uma fração."""

from datetime import datetime, timezone

import pytest

from app import models, rate_limit
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


def auth(credencial):
    return {"Authorization": f"Bearer {credencial}"}


def gerar_qr(client, condominio, indice=0):
    fracao_id = condominio["fracoes"][indice]["id"]
    resposta = client.post(f"/fracoes/{fracao_id}/qr", headers=auth(condominio["credencial_admin"]))
    return resposta.json()["token"]


def entrar(client, token, nome):
    return client.post("/identidades", json={"token": token, "nome": nome})


def listar(client, condominio, credencial=None, indice=0):
    fracao_id = condominio["fracoes"][indice]["id"]
    credencial = credencial or condominio["credencial_admin"]
    return client.get(f"/fracoes/{fracao_id}/qr", headers=auth(credencial))


def qr_do_token(db, token):
    return db.query(models.QrToken).filter_by(token_hash=hash_token(token)).one()


# --- Listar QR codes ativos ---------------------------------------------------


def test_lista_qr_ativos_sem_token_com_data_e_residentes(client):
    condominio = novo_condominio(client)
    primeiro = gerar_qr(client, condominio)
    gerar_qr(client, condominio)
    assert entrar(client, primeiro, "Marta Silva").status_code == 201
    assert entrar(client, primeiro, "Rui Costa").status_code == 201

    r = listar(client, condominio)
    assert r.status_code == 200
    itens = r.json()
    assert len(itens) == 2
    assert all(set(item) == {"id", "criado_em", "n_residentes"} for item in itens)
    assert [item["n_residentes"] for item in itens] == [2, 0]


def test_lista_nao_inclui_revogados(client, db):
    condominio = novo_condominio(client)
    token = gerar_qr(client, condominio)
    qr_do_token(db, token).revogado_em = datetime.now(timezone.utc)
    db.commit()

    assert listar(client, condominio).json() == []


def test_residente_removido_nao_conta(client, db):
    condominio = novo_condominio(client)
    token = gerar_qr(client, condominio)
    criada = entrar(client, token, "Marta Silva").json()
    db.get(models.Identidade, criada["id"]).removida_em = datetime.now(timezone.utc)
    db.commit()

    assert listar(client, condominio).json()[0]["n_residentes"] == 0


def test_listar_qr_sem_credencial_401(client):
    condominio = novo_condominio(client)
    fracao_id = condominio["fracoes"][0]["id"]
    assert client.get(f"/fracoes/{fracao_id}/qr").status_code == 401


def test_listar_qr_residente_403(client):
    condominio = novo_condominio(client)
    credencial = entrar(client, gerar_qr(client, condominio), "Marta Silva").json()["credencial"]
    r = listar(client, condominio, credencial=credencial)
    assert r.status_code == 403
    assert r.json()["codigo"] == "sem_permissao"


def test_listar_qr_outro_condominio_404(client):
    condominio = novo_condominio(client)
    outro = novo_condominio(client)
    r = listar(client, condominio, credencial=outro["credencial_admin"])
    assert r.status_code == 404


def test_listar_qr_fracao_inexistente_404(client):
    condominio = novo_condominio(client)
    r = client.get("/fracoes/999999/qr", headers=auth(condominio["credencial_admin"]))
    assert r.status_code == 404
