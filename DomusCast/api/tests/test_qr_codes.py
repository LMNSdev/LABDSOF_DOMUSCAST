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


# --- Revogar ------------------------------------------------------------------


def revogar_todos(client, condominio, credencial=None, indice=0):
    fracao_id = condominio["fracoes"][indice]["id"]
    credencial = credencial or condominio["credencial_admin"]
    return client.post(f"/fracoes/{fracao_id}/qr/revogar", headers=auth(credencial))


def revogar(client, qr_id, credencial):
    return client.post(f"/qr/{qr_id}/revogar", headers=auth(credencial))


def test_revogar_todos_devolve_numero_e_bloqueia_entradas(client):
    condominio = novo_condominio(client)
    tokens = [gerar_qr(client, condominio), gerar_qr(client, condominio)]

    r = revogar_todos(client, condominio)
    assert r.status_code == 200
    assert r.json() == {"revogados": 2}
    for token in tokens:
        entrada = entrar(client, token, "Marta Silva")
        assert entrada.status_code == 404
        assert entrada.json()["codigo"] == "qr_invalido"
    assert listar(client, condominio).json() == []


def test_revogar_todos_sem_ativos_devolve_0(client):
    condominio = novo_condominio(client)
    r = revogar_todos(client, condominio)
    assert r.status_code == 200
    assert r.json() == {"revogados": 0}


def test_revogar_todos_so_afeta_a_fracao(client):
    condominio = novo_condominio(client, n_fracoes=2)
    gerar_qr(client, condominio, 0)
    outro_token = gerar_qr(client, condominio, 1)

    assert revogar_todos(client, condominio, indice=0).json() == {"revogados": 1}
    assert entrar(client, outro_token, "Rui Costa").status_code == 201


def test_revogar_um_so_afeta_esse(client, db):
    condominio = novo_condominio(client)
    primeiro = gerar_qr(client, condominio)
    segundo = gerar_qr(client, condominio)

    r = revogar(client, qr_do_token(db, primeiro).id, condominio["credencial_admin"])
    assert r.status_code == 200
    assert r.json() == {"revogados": 1}
    assert entrar(client, primeiro, "Marta Silva").status_code == 404
    assert entrar(client, segundo, "Marta Silva").status_code == 201


def test_revogar_nao_afeta_identidades(client, db):
    condominio = novo_condominio(client)
    token = gerar_qr(client, condominio)
    credencial = entrar(client, token, "Marta Silva").json()["credencial"]

    assert revogar(client, qr_do_token(db, token).id, condominio["credencial_admin"]).status_code == 200
    assert client.get("/reportes", headers=auth(credencial)).status_code == 200


def test_revogar_duas_vezes_404(client, db):
    condominio = novo_condominio(client)
    qr_id = qr_do_token(db, gerar_qr(client, condominio)).id
    assert revogar(client, qr_id, condominio["credencial_admin"]).status_code == 200
    assert revogar(client, qr_id, condominio["credencial_admin"]).status_code == 404


def test_revogar_qr_inexistente_404(client):
    condominio = novo_condominio(client)
    assert revogar(client, 999999, condominio["credencial_admin"]).status_code == 404


def test_revogar_residente_403(client, db):
    condominio = novo_condominio(client)
    token = gerar_qr(client, condominio)
    credencial = entrar(client, token, "Marta Silva").json()["credencial"]

    assert revogar(client, qr_do_token(db, token).id, credencial).status_code == 403
    assert revogar_todos(client, condominio, credencial=credencial).status_code == 403
    assert entrar(client, token, "Rui Costa").status_code == 201


def test_revogar_sem_credencial_401(client, db):
    condominio = novo_condominio(client)
    token = gerar_qr(client, condominio)
    fracao_id = condominio["fracoes"][0]["id"]
    assert client.post(f"/qr/{qr_do_token(db, token).id}/revogar").status_code == 401
    assert client.post(f"/fracoes/{fracao_id}/qr/revogar").status_code == 401


def test_revogar_outro_condominio_404(client, db):
    condominio = novo_condominio(client)
    token = gerar_qr(client, condominio)
    outro = novo_condominio(client)

    assert revogar(client, qr_do_token(db, token).id, outro["credencial_admin"]).status_code == 404
    assert revogar_todos(client, condominio, credencial=outro["credencial_admin"]).status_code == 404
    assert entrar(client, token, "Marta Silva").status_code == 201
