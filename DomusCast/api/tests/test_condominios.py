"""US-01: criar condomínio, consultar frações e gerar QR codes por fração."""

import hashlib

import pytest

from app import models, rate_limit


@pytest.fixture(autouse=True)
def limpar_rate_limit():
    rate_limit.reset()
    yield
    rate_limit.reset()


def criar(client, n_fracoes=3, nome="Edifício Rua das Flores, 12", nome_admin="Ana Costa"):
    return client.post(
        "/condominios",
        json={"nome": nome, "nome_admin": nome_admin, "n_fracoes": n_fracoes},
    )


def auth(credencial):
    return {"Authorization": f"Bearer {credencial}"}


# --- Criar condomínio ---------------------------------------------------------


def test_criar_condominio_devolve_credencial_e_fracoes(client):
    r = criar(client, n_fracoes=3)
    assert r.status_code == 201
    data = r.json()
    assert data["nome"] == "Edifício Rua das Flores, 12"
    assert data["n_fracoes"] == 3
    assert len(data["credencial_admin"]) >= 32
    assert [f["designacao"] for f in data["fracoes"]] == ["A", "B", "C"]


def test_criador_e_o_primeiro_administrador(client, db):
    data = criar(client).json()
    admins = db.query(models.Administrador).filter_by(condominio_id=data["id"]).all()
    assert len(admins) == 1
    assert admins[0].nome == "Ana Costa"


def test_credencial_admin_guardada_so_como_hash(client, db):
    data = criar(client).json()
    admin = db.query(models.Administrador).filter_by(condominio_id=data["id"]).one()
    assert admin.credencial_hash != data["credencial_admin"]
    assert admin.credencial_hash == hashlib.sha256(data["credencial_admin"].encode()).hexdigest()


def test_designacoes_continuam_depois_do_z(client):
    data = criar(client, n_fracoes=28).json()
    designacoes = [f["designacao"] for f in data["fracoes"]]
    assert designacoes[25] == "Z"
    assert designacoes[26:] == ["AA", "AB"]


@pytest.mark.parametrize("n", [0, 201])
def test_limite_de_fracoes(client, n):
    assert criar(client, n_fracoes=n).status_code == 422


def test_aceita_o_maximo_de_200_fracoes(client):
    assert criar(client, n_fracoes=200).status_code == 201


@pytest.mark.parametrize("campo", ["nome", "nome_admin"])
def test_nomes_obrigatorios(client, campo):
    payload = {"nome": "Prédio", "nome_admin": "Ana", "n_fracoes": 2, campo: "   "}
    assert client.post("/condominios", json=payload).status_code == 422


def test_limite_de_pedidos_por_ip(client):
    for _ in range(5):
        assert criar(client, n_fracoes=1).status_code == 201
    r = criar(client, n_fracoes=1)
    assert r.status_code == 429


def test_pedido_recusado_por_validacao_nao_conta_para_o_limite(client):
    for _ in range(5):
        criar(client, n_fracoes=0)
    assert criar(client, n_fracoes=1).status_code == 201


# --- Consultar frações --------------------------------------------------------


def test_admin_consulta_as_fracoes(client):
    data = criar(client, n_fracoes=2).json()
    r = client.get(f"/condominios/{data['id']}/fracoes", headers=auth(data["credencial_admin"]))
    assert r.status_code == 200
    fracoes = r.json()
    assert [f["designacao"] for f in fracoes] == ["A", "B"]
    assert all(f["n_residentes"] == 0 for f in fracoes)


def test_fracoes_sem_credencial_401(client):
    data = criar(client).json()
    assert client.get(f"/condominios/{data['id']}/fracoes").status_code == 401


def test_fracoes_com_credencial_invalida_401(client):
    data = criar(client).json()
    r = client.get(f"/condominios/{data['id']}/fracoes", headers=auth("nao-existe"))
    assert r.status_code == 401


def test_fracoes_de_outro_condominio_403(client):
    a = criar(client, nome="Prédio A").json()
    b = criar(client, nome="Prédio B").json()
    r = client.get(f"/condominios/{b['id']}/fracoes", headers=auth(a["credencial_admin"]))
    assert r.status_code == 403


def test_admin_removido_401(client, db):
    data = criar(client).json()
    admin = db.query(models.Administrador).filter_by(condominio_id=data["id"]).one()
    admin.removido_em = models.func.now()
    db.commit()
    r = client.get(f"/condominios/{data['id']}/fracoes", headers=auth(data["credencial_admin"]))
    assert r.status_code == 401


# --- Gerar QR code ------------------------------------------------------------


def gerar_qr(client, data, indice=0, credencial=None):
    fracao_id = data["fracoes"][indice]["id"]
    return client.post(
        f"/fracoes/{fracao_id}/qr", headers=auth(credencial or data["credencial_admin"])
    )


def test_gerar_qr_devolve_token_e_link(client):
    data = criar(client).json()
    r = gerar_qr(client, data)
    assert r.status_code == 201
    qr = r.json()
    assert len(qr["token"]) >= 32
    assert qr["link"] == f"domuscast://entrar?t={qr['token']}"
    assert qr["fracao"] == "A"
    assert "criado_em" in qr


def test_token_guardado_so_como_hash_e_aponta_para_a_fracao(client, db):
    data = criar(client).json()
    token = gerar_qr(client, data, indice=1).json()["token"]
    guardado = (
        db.query(models.QrToken)
        .filter_by(token_hash=hashlib.sha256(token.encode()).hexdigest())
        .one()
    )
    assert guardado.fracao_id == data["fracoes"][1]["id"]
    assert db.query(models.QrToken).filter_by(token_hash=token).count() == 0


def test_tokens_sao_unicos_e_nao_derivam_da_fracao(client):
    data = criar(client, n_fracoes=3).json()
    tokens = [gerar_qr(client, data, indice=i).json()["token"] for i in range(3)]
    tokens.append(gerar_qr(client, data, indice=0).json()["token"])
    assert len(set(tokens)) == 4
    for t, f in zip(tokens, ["A", "B", "C", "A"], strict=True):
        assert t not in {f, str(data["fracoes"][0]["id"])}


def test_qr_anteriores_continuam_ativos(client, db):
    data = criar(client).json()
    gerar_qr(client, data)
    gerar_qr(client, data)
    fracao_id = data["fracoes"][0]["id"]
    tokens = db.query(models.QrToken).filter_by(fracao_id=fracao_id).all()
    assert len(tokens) == 2
    assert all(t.revogado_em is None for t in tokens)


def test_gerar_qr_sem_credencial_401(client):
    data = criar(client).json()
    fracao_id = data["fracoes"][0]["id"]
    assert client.post(f"/fracoes/{fracao_id}/qr").status_code == 401


def test_gerar_qr_de_outro_condominio_403(client):
    a = criar(client, nome="Prédio A").json()
    b = criar(client, nome="Prédio B").json()
    assert gerar_qr(client, b, credencial=a["credencial_admin"]).status_code == 403


def test_gerar_qr_fracao_inexistente_404(client):
    data = criar(client).json()
    r = client.post("/fracoes/999999/qr", headers=auth(data["credencial_admin"]))
    assert r.status_code == 404
