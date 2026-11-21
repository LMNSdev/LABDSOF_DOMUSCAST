"""US-23: o administrador lista e remove as identidades de uma fração."""

from datetime import datetime, timezone

import pytest

from app import models, rate_limit
from tests.test_reportes import auth, reportar


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
    resposta = client.post(f"/fracoes/{fracao_id}/qr", headers=auth(condominio["credencial_admin"]))
    return resposta.json()["token"]


def entrar(client, token, nome):
    return client.post("/identidades", json={"token": token, "nome": nome})


def listar(client, condominio, credencial=None, indice=0):
    fracao_id = condominio["fracoes"][indice]["id"]
    credencial = credencial or condominio["credencial_admin"]
    return client.get(f"/fracoes/{fracao_id}/identidades", headers=auth(credencial))


def remover(client, identidade_id, credencial):
    return client.delete(f"/identidades/{identidade_id}", headers=auth(credencial))


@pytest.fixture
def fracao_com_marta(client):
    """Condomínio com a Marta Silva na fração A; devolve (condominio, token, identidade)."""
    condominio = novo_condominio(client)
    token = gerar_qr(client, condominio)
    marta = entrar(client, token, "Marta Silva").json()
    return condominio, token, marta


# --- Listar identidades -------------------------------------------------------


def test_lista_identidades_ativas_com_nome_e_data(client, db, fracao_com_marta):
    condominio, token, marta = fracao_com_marta
    rui = entrar(client, token, "Rui Costa").json()
    db.get(models.Identidade, rui["id"]).removida_em = datetime.now(timezone.utc)
    db.commit()

    r = listar(client, condominio)
    assert r.status_code == 200
    itens = r.json()
    assert [item["nome"] for item in itens] == ["Marta Silva"]
    assert set(itens[0]) == {"id", "nome", "criado_em"}
    assert itens[0]["id"] == marta["id"]


def test_listar_identidades_sem_credencial_401(client, fracao_com_marta):
    condominio, _, _ = fracao_com_marta
    fracao_id = condominio["fracoes"][0]["id"]
    assert client.get(f"/fracoes/{fracao_id}/identidades").status_code == 401


def test_listar_identidades_residente_403(client, fracao_com_marta):
    condominio, _, marta = fracao_com_marta
    assert listar(client, condominio, credencial=marta["credencial"]).status_code == 403


def test_listar_identidades_outro_condominio_404(client, fracao_com_marta):
    condominio, _, _ = fracao_com_marta
    outro = novo_condominio(client)
    assert listar(client, condominio, credencial=outro["credencial_admin"]).status_code == 404


# --- Remover identidade -------------------------------------------------------


def test_remover_apaga_nome_e_regista_admin(client, db, fracao_com_marta):
    condominio, _, marta = fracao_com_marta

    r = remover(client, marta["id"], condominio["credencial_admin"])
    assert r.status_code == 204

    identidade = db.get(models.Identidade, marta["id"])
    db.refresh(identidade)
    admin = db.query(models.Administrador).filter_by(condominio_id=condominio["id"]).one()
    assert identidade.nome is None
    assert identidade.nome_normalizado is None
    assert identidade.removida_em is not None
    assert identidade.removida_por == admin.id
    assert listar(client, condominio).json() == []


def test_credencial_removida_recebe_401(client, fracao_com_marta):
    condominio, _, marta = fracao_com_marta
    assert remover(client, marta["id"], condominio["credencial_admin"]).status_code == 204

    assert client.get("/reportes", headers=auth(marta["credencial"])).status_code == 401
    assert reportar(client, marta["credencial"], "Fuga na garagem").status_code == 401


def test_reportes_mantem_se_sem_autor(client, fracao_com_marta):
    condominio, _, marta = fracao_com_marta
    criado = reportar(client, marta["credencial"], "Luz da escada fundida", mostrar_nome="true")
    assert criado.status_code == 201

    assert remover(client, marta["id"], condominio["credencial_admin"]).status_code == 204
    reportes = client.get("/reportes", headers=auth(condominio["credencial_admin"])).json()
    reporte = next(r for r in reportes if r["id"] == criado.json()["id"])
    assert reporte["descricao"] == "Luz da escada fundida"
    assert reporte["autor_nome"] is None


def test_mesmo_nome_volta_a_entrar_depois_de_remover(client, fracao_com_marta):
    condominio, token, marta = fracao_com_marta
    assert remover(client, marta["id"], condominio["credencial_admin"]).status_code == 204
    assert entrar(client, token, "Marta Silva").status_code == 201


def test_remover_duas_vezes_404(client, fracao_com_marta):
    condominio, _, marta = fracao_com_marta
    assert remover(client, marta["id"], condominio["credencial_admin"]).status_code == 204
    assert remover(client, marta["id"], condominio["credencial_admin"]).status_code == 404


def test_remover_inexistente_404(client, fracao_com_marta):
    condominio, _, _ = fracao_com_marta
    assert remover(client, 999999, condominio["credencial_admin"]).status_code == 404


def test_remover_residente_403(client, fracao_com_marta):
    condominio, token, marta = fracao_com_marta
    rui = entrar(client, token, "Rui Costa").json()
    assert remover(client, marta["id"], rui["credencial"]).status_code == 403
    assert client.get("/reportes", headers=auth(marta["credencial"])).status_code == 200


def test_remover_sem_credencial_401(client, fracao_com_marta):
    _, _, marta = fracao_com_marta
    assert client.delete(f"/identidades/{marta['id']}").status_code == 401


def test_remover_outro_condominio_404(client, fracao_com_marta):
    _, _, marta = fracao_com_marta
    outro = novo_condominio(client)
    assert remover(client, marta["id"], outro["credencial_admin"]).status_code == 404
    assert client.get("/reportes", headers=auth(marta["credencial"])).status_code == 200
