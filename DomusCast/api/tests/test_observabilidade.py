"""T-07: logs estruturados e métricas iniciais da API e do worker-calendario (8.7)."""

import json
import logging
from datetime import datetime, timezone
from uuid import uuid4

import httpx
import pytest
from fastapi.testclient import TestClient
from prometheus_client import REGISTRY

from app import models
from app.main import app
from app.observabilidade import log as log_api
from app.security import hash_token
from app.worker.calendario import metricas, processar_job
from app.worker.calendario_provider import ServicoCalendarioProvider


def _valor(nome: str, **etiquetas) -> float:
    return REGISTRY.get_sample_value(nome, etiquetas) or 0.0


@pytest.fixture
def linhas_de_log():
    """Linhas JSON que a API escreve no log durante o teste."""

    class Recolha(logging.Handler):
        def __init__(self):
            super().__init__()
            self.linhas = []

        def emit(self, registo):
            self.linhas.append(json.loads(self.format(registo)))

    recolha = Recolha()
    recolha.setFormatter(log_api.handlers[0].formatter)
    log_api.addHandler(recolha)
    yield recolha.linhas
    log_api.removeHandler(recolha)


def _admin(db):
    condominio = models.Condominio(nome=f"Condomínio {uuid4().hex}", n_fracoes=1)
    db.add(condominio)
    db.flush()
    token = uuid4().hex
    admin = models.Administrador(
        condominio_id=condominio.id, nome="Ana Ribeiro", credencial_hash=hash_token(token)
    )
    db.add(admin)
    db.commit()
    return admin, token


# --- Logs da API -----------------------------------------------------------------

def test_cada_pedido_gera_uma_linha_json_com_o_modelo_da_rota(client, db, linhas_de_log):
    admin, token = _admin(db)

    r = client.get(
        "/reportes/999999?token=segredo-do-ical",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert r.status_code == 404
    linha = linhas_de_log[-1]
    assert linha["componente"] == "api"
    assert linha["nivel"] == "WARNING"
    assert linha["metodo"] == "GET"
    assert linha["rota"] == "/reportes/{reporte_id}"
    assert linha["status"] == 404
    assert linha["duracao_ms"] >= 0
    assert linha["request_id"] == r.headers["X-Request-ID"]
    assert linha["administrador_id"] == admin.id
    texto = json.dumps(linha)
    # Nunca o caminho real, a query string nem o nome de quem fez o pedido (8.7, TM-08).
    assert "999999" not in texto
    assert "segredo-do-ical" not in texto
    assert "Ana Ribeiro" not in texto


def test_pedido_sem_credencial_nao_tem_utilizador_no_log(client, linhas_de_log):
    assert client.get("/reportes").status_code == 401

    linha = linhas_de_log[-1]
    assert linha["status"] == 401
    assert "administrador_id" not in linha
    assert "identidade_id" not in linha


def test_health_e_metrics_nao_entram_no_log(client, linhas_de_log):
    client.get("/health")
    client.get("/metrics")

    assert linhas_de_log == []


def test_request_id_da_app_e_reutilizado_se_for_valido(client, linhas_de_log):
    r = client.get("/reportes", headers={"X-Request-ID": "app-1234abcd"})
    assert r.headers["X-Request-ID"] == "app-1234abcd"
    assert r.json()["request_id"] == "app-1234abcd"
    assert linhas_de_log[-1]["request_id"] == "app-1234abcd"


@pytest.mark.parametrize("recebido", ["curto", "tem espacos;e=simbolos", "x" * 65])
def test_request_id_invalido_e_substituido(client, recebido):
    r = client.get("/reportes", headers={"X-Request-ID": recebido})
    assert r.headers["X-Request-ID"] != recebido
    assert len(r.headers["X-Request-ID"]) == 36


def test_excecao_nao_tratada_da_500_com_stack_trace_e_conta_em_erros(db, linhas_de_log):
    @app.get("/_teste_erro_t07", include_in_schema=False)
    def rebenta():
        raise RuntimeError("falha de teste")

    antes = _valor("erros_total")
    try:
        with TestClient(app, raise_server_exceptions=False) as cliente:
            r = cliente.get("/_teste_erro_t07")
    finally:
        app.router.routes[:] = [
            rota for rota in app.router.routes if getattr(rota, "path", "") != "/_teste_erro_t07"
        ]

    assert r.status_code == 500
    assert r.json()["codigo"] == "erro_interno"
    assert r.json()["request_id"] == r.headers["X-Request-ID"]
    assert _valor("erros_total") == antes + 1
    linha = linhas_de_log[-1]
    assert linha["nivel"] == "ERROR"
    assert linha["status"] == 500
    assert "RuntimeError: falha de teste" in linha["stack_trace"]


# --- Métricas da API -------------------------------------------------------------

def test_metrics_conta_pedidos_por_rota_e_codigo(client):
    etiquetas = {"metodo": "GET", "rota": "/reportes", "codigo": "401"}
    antes = _valor("pedidos_total", **etiquetas)
    duracoes = _valor("pedido_duracao_segundos_count", metodo="GET", rota="/reportes")

    client.get("/reportes")
    client.get("/reportes")

    assert _valor("pedidos_total", **etiquetas) == antes + 2
    assert _valor("pedido_duracao_segundos_count", metodo="GET", rota="/reportes") == duracoes + 2


def test_caminho_sem_rota_conta_num_so_valor(client):
    antes = _valor("pedidos_total", metodo="GET", rota="sem_rota", codigo="404")
    client.get("/nao/existe/123")
    client.get("/outro/caminho")
    assert _valor("pedidos_total", metodo="GET", rota="sem_rota", codigo="404") == antes + 2


def test_endpoint_metrics_em_formato_prometheus(client):
    client.get("/reportes")

    r = client.get("/metrics")

    assert r.status_code == 200
    assert r.headers["content-type"].startswith("text/plain")
    assert 'pedidos_total{codigo="401",metodo="GET",rota="/reportes"}' in r.text
    assert "pedido_duracao_segundos_bucket" in r.text
    assert "erros_total" in r.text
    # O /metrics não aparece na documentação pública da API.
    assert "/metrics" not in client.get("/openapi.json").json()["paths"]


# --- Métricas do worker-calendario ------------------------------------------------

def _reuniao_com_job(db):
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


def _provider(resposta: httpx.Response) -> ServicoCalendarioProvider:
    return ServicoCalendarioProvider(
        "http://simulador",
        client=httpx.Client(
            base_url="http://simulador", transport=httpx.MockTransport(lambda _: resposta)
        ),
    )


AGORA = datetime(2030, 1, 1, 12, 0, tzinfo=timezone.utc)


def test_worker_conta_falhas_de_integracao_por_motivo(db):
    _, job = _reuniao_com_job(db)
    etiquetas = {"provider": "calendario", "motivo": "indisponivel"}
    antes = _valor("integracao_falhas_total", **etiquetas)
    duracoes = _valor("job_duracao_segundos_count", tipo="publicar_calendario")

    processar_job(db, job, _provider(httpx.Response(503)), AGORA)

    assert _valor("integracao_falhas_total", **etiquetas) == antes + 1
    assert _valor("job_duracao_segundos_count", tipo="publicar_calendario") == duracoes + 1


def test_worker_conta_job_falhado_a_quinta_tentativa(db):
    _, job = _reuniao_com_job(db)
    job.tentativas = 4
    db.commit()
    antes = _valor("jobs_falhados_total", tipo="publicar_calendario")

    processar_job(db, job, _provider(httpx.Response(503)), AGORA)

    db.refresh(job)
    assert job.estado == models.EstadoJob.falhou
    assert _valor("jobs_falhados_total", tipo="publicar_calendario") == antes + 1


def test_worker_metrics_inclui_jobs_pendentes_da_base_de_dados(db):
    _reuniao_com_job(db)
    pendentes = (
        db.query(models.Job)
        .filter_by(tipo="publicar_calendario", estado=models.EstadoJob.pendente)
        .count()
    )

    texto = metricas(db).decode()

    assert f'jobs_pendentes{{tipo="publicar_calendario"}} {float(pendentes)}' in texto
    assert "integracao_falhas_total" in texto
    assert "job_duracao_segundos_bucket" in texto
