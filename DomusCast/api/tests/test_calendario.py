"""US-28: publicar a reunião no calendário externo (simulador, cliente e Worker)."""

import json
import time
from datetime import datetime, timedelta, timezone
from uuid import uuid4

import httpx
import pytest
from fastapi.testclient import TestClient

from app import models
from app.calendario import FalhaCalendario, ServicoCalendarioProvider, validar_resposta
from app.security import hash_token
from app.worker import executar_um, processar_job, repor_jobs_interrompidos
from simulador.main import app as simulador_app
from simulador.main import estado as estado_simulador

AGORA = datetime(2030, 1, 1, 12, 0, tzinfo=timezone.utc)
INICIO = "2030-11-25T19:00:00+00:00"
FIM = "2030-11-25T21:00:00+00:00"


@pytest.fixture
def simulador():
    estado_simulador.limpar()
    with TestClient(simulador_app) as cliente:
        yield cliente
    estado_simulador.limpar()


@pytest.fixture
def provider(simulador):
    return ServicoCalendarioProvider("http://simulador", client=simulador)


@pytest.fixture
def sem_outros_jobs(db):
    # A base de dados dos testes é partilhada: outros testes deixam jobs pendentes.
    db.query(models.Job).filter(models.Job.estado == models.EstadoJob.pendente).update(
        {models.Job.estado: models.EstadoJob.concluido}
    )
    db.commit()


def _caos(simulador, modo, atraso_ms=None):
    corpo = {"modo": modo} if atraso_ms is None else {"modo": modo, "atraso_ms": atraso_ms}
    assert simulador.post("/_chaos", json=corpo).status_code == 200


def _reuniao(db):
    condominio = models.Condominio(nome=f"Condomínio {uuid4().hex}", n_fracoes=1)
    db.add(condominio)
    db.flush()
    reuniao = models.Reuniao(
        condominio_id=condominio.id,
        data_hora=datetime(2030, 11, 25, 19, 0, tzinfo=timezone.utc),
        local="Sala do condomínio",
    )
    db.add(reuniao)
    db.flush()
    job = models.Job(
        tipo="publicar_calendario",
        chave_idempotencia=f"publicar_calendario:{reuniao.id}",
        payload=json.dumps({"reuniao_id": reuniao.id}),
    )
    db.add(job)
    db.commit()
    return reuniao, job


def _provider_falso(resposta):
    """Cliente cujo pedido devolve `resposta` (um httpx.Response ou uma exceção)."""

    def tratar(pedido):
        if isinstance(resposta, Exception):
            raise resposta
        return resposta

    return ServicoCalendarioProvider(
        "http://simulador",
        client=httpx.Client(base_url="http://simulador", transport=httpx.MockTransport(tratar)),
    )


def _eventos(simulador, reuniao):
    return simulador.get(f"/calendars/condominio{reuniao.condominio_id}/events").json()["items"]


# --- Simulador ----------------------------------------------------------------


def test_simulador_cria_evento_e_recusa_o_mesmo_id_com_409(simulador):
    corpo = {"id": "domuscast1", "summary": "Assembleia", "location": "Sala",
             "start": {"dateTime": INICIO}, "end": {"dateTime": FIM}}

    primeira = simulador.post("/calendars/c1/events", json=corpo)
    segunda = simulador.post("/calendars/c1/events", json=corpo)

    assert primeira.status_code == 200
    assert primeira.json()["id"] == "domuscast1"
    assert primeira.json()["status"] == "confirmed"
    assert segunda.status_code == 409
    assert len(simulador.get("/calendars/c1/events").json()["items"]) == 1


@pytest.mark.parametrize(
    "corpo",
    [
        {"summary": "Assembleia", "end": {"dateTime": FIM}},
        {"summary": "Assembleia", "start": {"dateTime": FIM}, "end": {"dateTime": INICIO}},
        {"id": "ID-INVALIDO", "summary": "A", "start": {"dateTime": INICIO}, "end": {"dateTime": FIM}},
    ],
)
def test_simulador_pedido_invalido_devolve_400(simulador, corpo):
    resposta = simulador.post("/calendars/c1/events", json=corpo)

    assert resposta.status_code == 400
    assert resposta.json()["error"]["code"] == 400


def test_simulador_modos_de_falha(simulador):
    corpo = {"summary": "A", "start": {"dateTime": INICIO}, "end": {"dateTime": FIM}}

    _caos(simulador, "indisponivel")
    assert simulador.post("/calendars/c1/events", json=corpo).status_code == 503

    _caos(simulador, "limite")
    limite = simulador.post("/calendars/c1/events", json=corpo)
    assert limite.status_code == 429
    assert limite.headers["Retry-After"] == "30"

    _caos(simulador, "incompleto")
    assert "id" not in simulador.post("/calendars/c1/events", json=corpo).json()

    _caos(simulador, "invalido")
    assert simulador.post("/calendars/c1/events", json=corpo).json()["start"]["dateTime"].startswith(
        "2026-13"
    )

    _caos(simulador, "lento", atraso_ms=200)
    inicio = time.monotonic()
    assert simulador.post("/calendars/c1/events", json=corpo).status_code == 200
    assert time.monotonic() - inicio >= 0.2
    assert simulador.get("/_chaos").json() == {"modo": "lento", "atraso_ms": 200}


def test_simulador_recusa_modo_desconhecido(simulador):
    assert simulador.post("/_chaos", json={"modo": "partido"}).status_code == 400


# --- Cliente do calendário -----------------------------------------------------


def test_publica_no_calendario_do_condominio_com_id_proprio(db, simulador, provider):
    reuniao, _ = _reuniao(db)

    evento_id = provider.publicar(reuniao)

    assert evento_id == f"domuscast{reuniao.id}"
    [evento] = _eventos(simulador, reuniao)
    assert evento["location"] == "Sala do condomínio"
    assert datetime.fromisoformat(evento["start"]["dateTime"]) == reuniao.data_hora.replace(
        tzinfo=timezone.utc
    )
    assert datetime.fromisoformat(evento["end"]["dateTime"]) - datetime.fromisoformat(
        evento["start"]["dateTime"]
    ) == timedelta(hours=2)


def test_pedido_usa_timeout_de_10_segundos(db):
    reuniao, _ = _reuniao(db)
    timeouts = []

    def tratar(pedido):
        timeouts.append(pedido.extensions["timeout"]["read"])
        return httpx.Response(503)

    provider = ServicoCalendarioProvider(
        "http://simulador",
        client=httpx.Client(base_url="http://simulador", transport=httpx.MockTransport(tratar)),
    )
    with pytest.raises(FalhaCalendario):
        provider.publicar(reuniao)

    assert timeouts == [10.0]


@pytest.mark.parametrize(
    ("resposta", "motivo"),
    [
        (httpx.ReadTimeout("lento"), "atrasado"),
        (httpx.ConnectError("recusada"), "indisponivel"),
        (httpx.Response(503), "indisponivel"),
        (httpx.Response(429, headers={"Retry-After": "30"}), "atrasado"),
        (httpx.Response(400), "recusado"),
        (httpx.Response(200, text="não é json"), "invalido"),
        (httpx.Response(200, json={"status": "confirmed"}), "incompleto"),
    ],
)
def test_falhas_do_servico_sao_detetadas(db, resposta, motivo):
    reuniao, _ = _reuniao(db)

    with pytest.raises(FalhaCalendario) as falha:
        _provider_falso(resposta).publicar(reuniao)

    assert falha.value.motivo.startswith(motivo)


@pytest.mark.parametrize(
    ("corpo", "motivo"),
    [
        ({"id": "x", "status": "confirmed", "end": {"dateTime": FIM}}, "incompleto"),
        ({"status": "confirmed", "start": {"dateTime": INICIO}, "end": {"dateTime": FIM}}, "incompleto"),
        ({"id": "x", "status": "confirmed", "start": {"dateTime": "2026-13-45T25:61:00"},
          "end": {"dateTime": FIM}}, "invalido"),
        ({"id": "x", "status": "confirmed", "start": {"dateTime": FIM},
          "end": {"dateTime": INICIO}}, "invalido"),
        ({"id": "x", "status": "confirmed", "start": {"dateTime": "2030-11-25T19:00:00"},
          "end": {"dateTime": "2030-11-25T21:00:00"}}, "invalido"),
        ({"id": "x", "status": "cancelled", "start": {"dateTime": INICIO},
          "end": {"dateTime": FIM}}, "invalido"),
    ],
)
def test_resposta_incompleta_ou_invalida_conta_como_falha(corpo, motivo):
    with pytest.raises(FalhaCalendario) as falha:
        validar_resposta(corpo)

    assert falha.value.motivo.startswith(motivo)


# --- Worker --------------------------------------------------------------------


def test_worker_publica_e_marca_sincronizada(db, simulador, provider, sem_outros_jobs):
    reuniao, job = _reuniao(db)

    assert executar_um(db, provider) is True

    db.refresh(reuniao)
    db.refresh(job)
    assert reuniao.estado_sync == models.EstadoSyncReuniao.sincronizada
    assert reuniao.calendario_externo_id == f"domuscast{reuniao.id}"
    assert job.estado == models.EstadoJob.concluido
    assert job.tentativas == 1
    assert len(_eventos(simulador, reuniao)) == 1
    assert executar_um(db, provider) is False


@pytest.mark.parametrize(
    ("modo", "motivo"),
    [
        ("indisponivel", "indisponivel"),
        ("limite", "atrasado"),
        ("incompleto", "incompleto"),
        ("invalido", "invalido"),
    ],
)
def test_cada_falha_mantem_pendente_e_agenda_nova_tentativa(db, simulador, provider, modo, motivo):
    reuniao, job = _reuniao(db)
    _caos(simulador, modo)

    processar_job(db, job, provider, AGORA)

    db.refresh(reuniao)
    db.refresh(job)
    assert reuniao.estado_sync == models.EstadoSyncReuniao.pendente
    assert job.estado == models.EstadoJob.pendente
    assert job.tentativas == 1
    assert job.erro.startswith(motivo)
    assert job.proxima_tentativa_em is not None
    assert _eventos(simulador, reuniao) == []


def test_lento_mais_de_10_segundos_conta_como_falha(db):
    reuniao, job = _reuniao(db)

    processar_job(db, job, _provider_falso(httpx.ReadTimeout("lento")), AGORA)

    db.refresh(job)
    assert job.estado == models.EstadoJob.pendente
    assert job.erro == "atrasado: sem resposta em 10 s"
    assert db.get(models.Reuniao, reuniao.id).estado_sync == models.EstadoSyncReuniao.pendente


def test_400_conta_como_falha_normal_com_nova_tentativa(db):
    _, job = _reuniao(db)

    processar_job(db, job, _provider_falso(httpx.Response(400)), AGORA)

    db.refresh(job)
    assert job.estado == models.EstadoJob.pendente
    assert job.erro == "recusado: 400"
    assert job.proxima_tentativa_em.replace(tzinfo=timezone.utc) == AGORA + timedelta(minutes=1)


def test_backoff_1_2_4_8_minutos_e_alternativo_a_quinta_falha(db, client):
    reuniao, job = _reuniao(db)
    indisponivel = _provider_falso(httpx.Response(503))
    esperas = []

    for _ in range(4):
        processar_job(db, job, indisponivel, AGORA)
        db.refresh(job)
        esperas.append(job.proxima_tentativa_em.replace(tzinfo=timezone.utc) - AGORA)
        assert job.estado == models.EstadoJob.pendente
    processar_job(db, job, indisponivel, AGORA)

    db.refresh(job)
    db.refresh(reuniao)
    assert esperas == [timedelta(minutes=m) for m in (1, 2, 4, 8)]
    assert job.tentativas == 5
    assert job.estado == models.EstadoJob.falhou
    assert job.proxima_tentativa_em is None
    assert reuniao.estado_sync == models.EstadoSyncReuniao.alternativo
    # A reunião continua guardada e disponível na API.
    token = uuid4().hex
    db.add(models.Administrador(condominio_id=reuniao.condominio_id, nome="Ana",
                                credencial_hash=hash_token(token)))
    db.commit()
    [dados] = client.get(
        "/reunioes", headers={"Authorization": f"Bearer {token}"},
        params={"desde": "2000-01-01T00:00:00+00:00"},
    ).json()
    assert dados["estado_sync"] == "alternativo"
    assert dados["local"] == "Sala do condomínio"


@pytest.mark.parametrize(("unidade_s", "espera_s"), [(1.0, 30), (60.0, 60)])
def test_429_espera_o_maior_entre_backoff_e_retry_after(db, unidade_s, espera_s):
    _, job = _reuniao(db)
    limite = _provider_falso(httpx.Response(429, headers={"Retry-After": "30"}))

    processar_job(db, job, limite, AGORA, unidade_backoff_s=unidade_s)

    db.refresh(job)
    assert job.tentativas == 1
    assert job.proxima_tentativa_em.replace(tzinfo=timezone.utc) == AGORA + timedelta(seconds=espera_s)


def test_job_espera_pela_hora_da_nova_tentativa(db, simulador, provider, sem_outros_jobs):
    reuniao, job = _reuniao(db)
    _caos(simulador, "indisponivel")
    assert executar_um(db, provider) is True
    _caos(simulador, "ok")

    # Ainda dentro do minuto de espera: não volta a tentar.
    assert executar_um(db, provider) is False

    job.proxima_tentativa_em = datetime.now(timezone.utc) - timedelta(seconds=1)
    db.commit()
    assert executar_um(db, provider) is True
    db.refresh(reuniao)
    assert reuniao.estado_sync == models.EstadoSyncReuniao.sincronizada
    assert db.get(models.Job, job.id).tentativas == 2


def test_worker_que_caiu_depois_de_publicar_nao_duplica_o_evento(
    db, simulador, provider, sem_outros_jobs
):
    reuniao, job = _reuniao(db)
    # O Worker reservou o job e publicou, mas caiu antes de gravar o resultado.
    job.estado = models.EstadoJob.em_curso
    db.commit()
    provider.publicar(reuniao)

    assert repor_jobs_interrompidos(db) >= 1
    assert executar_um(db, provider) is True

    db.refresh(reuniao)
    assert reuniao.estado_sync == models.EstadoSyncReuniao.sincronizada
    assert reuniao.calendario_externo_id == f"domuscast{reuniao.id}"
    assert len(_eventos(simulador, reuniao)) == 1


def test_job_de_reuniao_ja_sincronizada_nao_chama_o_servico(db, simulador, provider):
    reuniao, job = _reuniao(db)
    reuniao.estado_sync = models.EstadoSyncReuniao.sincronizada
    db.commit()

    processar_job(db, job, provider, AGORA)

    db.refresh(job)
    assert job.estado == models.EstadoJob.concluido
    assert job.tentativas == 0
    assert _eventos(simulador, reuniao) == []


def test_job_com_payload_invalido_falha_sem_parar_o_worker(db, simulador, provider, sem_outros_jobs):
    _, job_mau = _reuniao(db)
    job_mau.payload = "{reuniao_id: x}"
    reuniao, job = _reuniao(db)
    db.commit()

    assert executar_um(db, provider) is True
    assert executar_um(db, provider) is True

    db.refresh(job_mau)
    db.refresh(reuniao)
    assert job_mau.estado == models.EstadoJob.falhou
    assert job_mau.erro == "payload inválido"
    assert reuniao.estado_sync == models.EstadoSyncReuniao.sincronizada


def test_desde_mostra_a_reuniao_quando_o_worker_muda_o_estado(db, client, simulador, provider):
    reuniao, job = _reuniao(db)
    token = uuid4().hex
    db.add(models.Administrador(condominio_id=reuniao.condominio_id, nome="Ana",
                                credencial_hash=hash_token(token)))
    ontem = datetime.now(timezone.utc) - timedelta(days=1)
    reuniao.criado_em = ontem
    reuniao.atualizado_em = ontem
    db.commit()
    desde = (datetime.now(timezone.utc) - timedelta(hours=1)).isoformat()

    def sincronizar():
        return client.get(
            "/reunioes", headers={"Authorization": f"Bearer {token}"}, params={"desde": desde}
        ).json()

    assert sincronizar() == []

    processar_job(db, job, provider, AGORA)

    [dados] = sincronizar()
    assert dados["id"] == reuniao.id
    assert dados["estado_sync"] == "sincronizada"
