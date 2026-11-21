"""US-13: agendar reunião (POST /reunioes) e listar reuniões (GET /reunioes)."""

import json
from datetime import datetime, timedelta, timezone
from uuid import uuid4

import pytest
from sqlalchemy.exc import OperationalError

from app import models
from app.security import hash_token

LOCAL = "Sala do condomínio"


def _condominio(db):
    condominio = models.Condominio(nome=f"Condomínio {uuid4().hex}", n_fracoes=1)
    db.add(condominio)
    db.flush()
    return condominio


def _admin(db, condominio=None):
    condominio = condominio or _condominio(db)
    token = uuid4().hex
    admin = models.Administrador(
        condominio_id=condominio.id, nome="Ana", credencial_hash=hash_token(token)
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


def _auth(token):
    return {"Authorization": f"Bearer {token}"}


def _futuro(dias=7):
    return (datetime.now(timezone.utc) + timedelta(days=dias)).replace(microsecond=0)


def _agendar(client, token, data_hora=None, local=LOCAL):
    data_hora = data_hora or _futuro()
    return client.post(
        "/reunioes",
        headers=_auth(token),
        json={"data_hora": data_hora.isoformat(), "local": local},
    )


def test_admin_agenda_reuniao_com_publicacao_pendente(client, db):
    admin, token = _admin(db)
    quando = datetime(2030, 11, 25, 19, 0, tzinfo=timezone(timedelta(hours=0)))

    resposta = _agendar(client, token, quando, "  Sala do condomínio  ")

    assert resposta.status_code == 201
    dados = resposta.json()
    assert dados["local"] == LOCAL
    assert dados["estado_sync"] == "pendente"
    assert datetime.fromisoformat(dados["data_hora"]) == quando
    reuniao = db.get(models.Reuniao, dados["id"])
    assert reuniao.condominio_id == admin.condominio_id


def test_hora_com_offset_e_guardada_no_instante_certo(client, db):
    _, token = _admin(db)
    # 19:00 em Lisboa no verão (UTC+1) são 18:00 UTC.
    quando = datetime(2030, 7, 1, 19, 0, tzinfo=timezone(timedelta(hours=1)))

    dados = _agendar(client, token, quando).json()

    assert datetime.fromisoformat(dados["data_hora"]) == datetime(
        2030, 7, 1, 18, 0, tzinfo=timezone.utc
    )


def test_agendar_cria_um_job_publicar_calendario(client, db):
    _, token = _admin(db)

    reuniao_id = _agendar(client, token).json()["id"]

    jobs = db.query(models.Job).filter_by(chave_idempotencia=f"publicar_calendario:{reuniao_id}").all()
    assert len(jobs) == 1
    assert jobs[0].tipo == "publicar_calendario"
    assert jobs[0].estado == models.EstadoJob.pendente
    assert json.loads(jobs[0].payload) == {"reuniao_id": reuniao_id}


@pytest.mark.parametrize(
    "data_hora",
    [
        "2020-01-01T19:00:00+00:00",  # no passado
        "2030-11-25T19:00:00",  # sem fuso
        "25/11/2030 19:00",  # formato inválido
    ],
)
def test_data_invalida_devolve_422(client, db, data_hora):
    _, token = _admin(db)

    resposta = client.post(
        "/reunioes", headers=_auth(token), json={"data_hora": data_hora, "local": LOCAL}
    )

    assert resposta.status_code == 422
    assert resposta.json()["codigo"] == "dados_invalidos"


@pytest.mark.parametrize("local", ["", "   ", "x" * 201])
def test_local_vazio_ou_acima_de_200_devolve_422(client, db, local):
    _, token = _admin(db)

    assert _agendar(client, token, local=local).status_code == 422


def test_local_com_200_caracteres_e_aceite(client, db):
    _, token = _admin(db)

    assert _agendar(client, token, local="x" * 200).status_code == 201


def test_campo_desconhecido_devolve_422(client, db):
    _, token = _admin(db)

    resposta = client.post(
        "/reunioes",
        headers=_auth(token),
        json={"data_hora": _futuro().isoformat(), "local": LOCAL, "titulo": "x"},
    )

    assert resposta.status_code == 422


def test_dados_invalidos_nao_criam_reuniao_nem_job(client, db):
    admin, token = _admin(db)

    _agendar(client, token, local="")

    assert db.query(models.Reuniao).filter_by(condominio_id=admin.condominio_id).count() == 0


def test_agendar_sem_credencial_401(client):
    resposta = client.post("/reunioes", json={"data_hora": _futuro().isoformat(), "local": LOCAL})

    assert resposta.status_code == 401


def test_residente_nao_agenda_403(client, db):
    token = _residente(db, _condominio(db))

    resposta = _agendar(client, token)

    assert resposta.status_code == 403
    assert resposta.json()["codigo"] == "sem_permissao"


def test_base_de_dados_indisponivel_devolve_503(client, db, monkeypatch):
    _, token = _admin(db)

    def falhar():
        raise OperationalError("COMMIT", {}, Exception("ligação perdida"))

    monkeypatch.setattr(db, "commit", falhar)
    resposta = _agendar(client, token)

    assert resposta.status_code == 503
    assert resposta.json()["codigo"] == "servico_indisponivel"


def test_admin_e_residente_veem_as_reunioes_do_condominio_por_data(client, db):
    admin, token_admin = _admin(db)
    token_residente = _residente(db, db.get(models.Condominio, admin.condominio_id))
    depois = _agendar(client, token_admin, _futuro(14), "Garagem").json()
    antes = _agendar(client, token_admin, _futuro(7)).json()

    for token in (token_admin, token_residente):
        resposta = client.get("/reunioes", headers=_auth(token))
        assert resposta.status_code == 200
        assert [r["id"] for r in resposta.json()] == [antes["id"], depois["id"]]


def test_lista_vazia_devolve_200(client, db):
    _, token = _admin(db)

    resposta = client.get("/reunioes", headers=_auth(token))

    assert resposta.status_code == 200
    assert resposta.json() == []


def test_nao_ve_reunioes_de_outro_condominio(client, db):
    _, token_outro = _admin(db)
    _agendar(client, token_outro)
    _, token = _admin(db)

    assert client.get("/reunioes", headers=_auth(token)).json() == []


def test_sem_desde_nao_mostra_reunioes_de_dias_anteriores(client, db):
    admin, token = _admin(db)
    db.add(
        models.Reuniao(
            condominio_id=admin.condominio_id,
            data_hora=datetime.now(timezone.utc) - timedelta(days=2),
            local="Reunião antiga",
        )
    )
    db.commit()

    assert client.get("/reunioes", headers=_auth(token)).json() == []


def test_desde_devolve_as_criadas_depois_dessa_data(client, db):
    _, token = _admin(db)
    criada = _agendar(client, token).json()
    criada_em = datetime.fromisoformat(criada["criado_em"])

    antes = client.get(
        "/reunioes", headers=_auth(token), params={"desde": (criada_em - timedelta(minutes=1)).isoformat()}
    ).json()
    depois = client.get(
        "/reunioes", headers=_auth(token), params={"desde": (criada_em + timedelta(minutes=1)).isoformat()}
    ).json()

    assert [r["id"] for r in antes] == [criada["id"]]
    assert depois == []


def test_listar_sem_credencial_401(client):
    assert client.get("/reunioes").status_code == 401
