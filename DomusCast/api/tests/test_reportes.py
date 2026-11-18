import pytest
from app import models, rate_limit


@pytest.fixture(autouse=True)
def limpar_rate_limit():
    rate_limit.reset()
    yield
    rate_limit.reset()


def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


def criar_sessao(client, nome="Marta Silva"):
    criar = client.post(
        "/condominios",
        json={"nome": "Prédio", "nome_admin": "Ana", "n_fracoes": 1},
    )
    condominio = criar.json()
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
    return admin, entrada["credencial"], fracao, entrada


def auth(credencial):
    return {"Authorization": f"Bearer {credencial}"}


def criar_duas_sessoes_na_mesma_fracao(client):
    criar = client.post(
        "/condominios",
        json={"nome": "Prédio", "nome_admin": "Ana", "n_fracoes": 1},
    )
    condominio = criar.json()
    fracao = condominio["fracoes"][0]
    admin = condominio["credencial_admin"]
    qr = client.post(
        f"/fracoes/{fracao['id']}/qr",
        headers={"Authorization": f"Bearer {admin}"},
    ).json()
    entrada_a = client.post(
        "/identidades",
        json={"token": qr["token"], "nome": "Marta Silva"},
    ).json()
    entrada_b = client.post(
        "/identidades",
        json={"token": qr["token"], "nome": "Rui Costa"},
    ).json()
    return admin, entrada_a["credencial"], entrada_b["credencial"], fracao


def test_criar_reporte(client):
    _, credencial, _, _ = criar_sessao(client)
    r = client.post(
        "/reportes",
        json={"descricao": "Torneira com fuga no 1.º andar"},
        headers=auth(credencial),
    )
    assert r.status_code == 201
    data = r.json()
    assert data["descricao"] == "Torneira com fuga no 1.º andar"
    assert data["estado"] == "aberto"
    assert data["mostrar_nome"] is False
    assert data["autor_nome"] is None
    assert data["fracao"] is None
    assert data["meu"] is True
    assert data["id"] is not None


def test_listar_reportes(client):
    _, credencial, _, _ = criar_sessao(client)
    client.post(
        "/reportes",
        json={"descricao": "Elevador avariado", "mostrar_nome": True},
        headers=auth(credencial),
    )
    r = client.get("/reportes", headers=auth(credencial))
    assert r.status_code == 200
    assert isinstance(r.json(), list)
    assert any(rep["descricao"] == "Elevador avariado" for rep in r.json())


def test_idempotencia(client):
    _, credencial, _, _ = criar_sessao(client)
    payload = {"descricao": "Luz partida na cave", "idempotency_key": "test-idem-key-001"}
    r1 = client.post("/reportes", json=payload, headers=auth(credencial))
    r2 = client.post("/reportes", json=payload, headers=auth(credencial))
    assert r1.status_code == 201
    assert r2.status_code == 201
    assert r1.json()["id"] == r2.json()["id"]


def test_mostrar_nome_desligado_por_defeito(client):
    _, credencial, _, _ = criar_sessao(client)
    criar = client.post(
        "/reportes",
        json={"descricao": "Fuga na garagem"},
        headers=auth(credencial),
    )
    assert criar.status_code == 201
    assert criar.json()["mostrar_nome"] is False


def test_residente_sem_mostrar_nome_nao_e_identificado_a_outro_residente(client):
    _, credencial_a, credencial_b, _ = criar_duas_sessoes_na_mesma_fracao(client)
    client.post(
        "/reportes",
        json={"descricao": "Fuga na garagem", "mostrar_nome": False},
        headers=auth(credencial_a),
    )
    resposta = client.get("/reportes", headers=auth(credencial_b))
    assert resposta.status_code == 200
    reporte = next(r for r in resposta.json() if r["descricao"] == "Fuga na garagem")
    assert reporte["autor_nome"] is None
    assert reporte["fracao"] is None


def test_residente_com_mostrar_nome_e_identificado_a_outro_residente(client):
    _, credencial_a, credencial_b, _ = criar_duas_sessoes_na_mesma_fracao(client)
    client.post(
        "/reportes",
        json={"descricao": "Escada", "mostrar_nome": True},
        headers=auth(credencial_a),
    )
    resposta = client.get("/reportes", headers=auth(credencial_b))
    reporte = next(r for r in resposta.json() if r["descricao"] == "Escada")
    assert reporte["autor_nome"] == "Marta Silva"
    assert reporte["fracao"] is None


def test_administrador_ve_nome_e_fracao(client):
    admin, credencial, fracao, entrada = criar_sessao(client)
    client.post(
        "/reportes",
        json={"descricao": "Elevador", "mostrar_nome": False},
        headers=auth(credencial),
    )
    resposta = client.get("/reportes", headers=auth(admin))
    reporte = next(r for r in resposta.json() if r["descricao"] == "Elevador")
    assert reporte["autor_nome"] == "Marta Silva"
    assert reporte["fracao"] == fracao["designacao"]


@pytest.mark.parametrize("campo", ["telefone", "email", "perfil"])
def test_campos_de_contacto_sao_rejeitados(client, campo):
    _, credencial, _, _ = criar_sessao(client)
    payload = {"descricao": "Fuga", campo: "dado pessoal"}
    resposta = client.post("/reportes", json=payload, headers=auth(credencial))
    assert resposta.status_code == 422


def test_pedido_com_foto_e_so_campos_previstos_e_aceite(client):
    _, credencial, _, _ = criar_sessao(client)
    payload = {
        "descricao": "Fuga",
        "foto_url": "https://exemplo.invalid/fuga.jpg",
        "idempotency_key": "chave-foto-001",
        "mostrar_nome": True,
    }
    resposta = client.post("/reportes", json=payload, headers=auth(credencial))
    assert resposta.status_code == 201


def test_sem_credencial_nao_cria_reporte(client):
    resposta = client.post("/reportes", json={"descricao": "Fuga"})
    assert resposta.status_code == 401


def test_sem_credencial_nao_lista_reportes(client):
    assert client.get("/reportes").status_code == 401


def test_administrador_nao_cria_reporte(client):
    admin, _, _, _ = criar_sessao(client)
    resposta = client.post(
        "/reportes",
        json={"descricao": "Fuga"},
        headers=auth(admin),
    )
    assert resposta.status_code == 403


def test_credencial_invalida_nao_lista_reportes(client):
    assert client.get("/reportes", headers=auth("credencial-que-nao-existe")).status_code == 401


def test_autor_ve_os_seus_reportes_como_meus(client):
    _, credencial_a, credencial_b, _ = criar_duas_sessoes_na_mesma_fracao(client)
    client.post(
        "/reportes",
        json={"descricao": "Fuga na garagem"},
        headers=auth(credencial_a),
    )
    do_autor = client.get("/reportes", headers=auth(credencial_a)).json()
    do_vizinho = client.get("/reportes", headers=auth(credencial_b)).json()
    assert do_autor[0]["meu"] is True
    assert do_autor[0]["mostrar_nome"] is False
    assert do_autor[0]["fracao"] is None
    assert do_vizinho[0]["meu"] is False


def test_residente_de_outro_condominio_nao_ve_os_reportes(client):
    _, credencial_a, _, _ = criar_sessao(client)
    _, credencial_b, _, _ = criar_sessao(client, nome="Rui Costa")
    client.post("/reportes", json={"descricao": "Fuga"}, headers=auth(credencial_a))
    assert client.get("/reportes", headers=auth(credencial_b)).json() == []


def test_identidade_nao_tem_campos_de_contacto():
    colunas = {c.name for c in models.Identidade.__table__.columns}
    assert colunas.isdisjoint({"telefone", "email", "perfil", "contacto"})
