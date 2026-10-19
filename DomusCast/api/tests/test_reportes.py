def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


def test_criar_reporte(client):
    r = client.post("/reportes", json={"descricao": "Torneira com fuga no 1.º andar"})
    assert r.status_code == 201
    data = r.json()
    assert data["descricao"] == "Torneira com fuga no 1.º andar"
    assert data["estado"] == "aberto"
    assert data["id"] is not None


def test_listar_reportes(client):
    client.post("/reportes", json={"descricao": "Elevador avariado"})
    r = client.get("/reportes")
    assert r.status_code == 200
    assert isinstance(r.json(), list)
    assert any(rep["descricao"] == "Elevador avariado" for rep in r.json())


def test_idempotencia(client):
    payload = {"descricao": "Luz partida na cave", "idempotency_key": "test-idem-key-001"}
    r1 = client.post("/reportes", json=payload)
    r2 = client.post("/reportes", json=payload)
    assert r1.status_code == 201
    assert r2.status_code == 201
    assert r1.json()["id"] == r2.json()["id"]
