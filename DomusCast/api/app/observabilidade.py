"""Logs estruturados e métricas iniciais da API (8.7, T-07).

- Uma linha JSON por pedido em stdout, com `request_id` e o modelo da rota
  (`/reportes/{reporte_id}`), nunca o caminho real nem a query string, que podem ter
  ids ou tokens (TM-08). Nunca nomes nem conteúdo.
- Métricas Prometheus em `GET /metrics`: pedidos por rota e código, latência (histograma,
  para o p95) e erros não tratados. O Caddy não encaminha `/metrics` (fica na rede interna).
"""

import json
import logging
import re
import sys
import time
from datetime import datetime, timezone
from uuid import uuid4

from fastapi import Request
from fastapi.responses import JSONResponse
from prometheus_client import Counter, Histogram

log = logging.getLogger("domuscast.api")

PEDIDOS = Counter(
    "pedidos", "Pedidos HTTP à API, por método, rota e código.", ["metodo", "rota", "codigo"]
)
DURACAO = Histogram(
    "pedido_duracao_segundos",
    "Duração dos pedidos HTTP à API, por método e rota.",
    ["metodo", "rota"],
    buckets=(0.025, 0.05, 0.1, 0.25, 0.5, 0.75, 1.0, 2.5, 5.0, 10.0),
)
ERROS = Counter("erros", "Exceções não tratadas na API.")

# Pedidos que não entram no log: o healthcheck corre de 10 em 10 s e o /metrics é lido
# pelo Prometheus; encheriam o log sem dizer nada. Continuam a contar nas métricas.
SEM_LOG = {"/health", "/metrics"}
# Um X-Request-ID vindo da app só é reutilizado se for curto e sem caracteres estranhos,
# para não se poder injetar texto nos logs.
REQUEST_ID_VALIDO = re.compile(r"^[A-Za-z0-9-]{8,64}$")


class FormatoJson(logging.Formatter):
    """Cada registo é um objeto JSON numa linha; `extra={"campos": {...}}` junta campos."""

    def format(self, registo: logging.LogRecord) -> str:
        dados = {
            "timestamp": datetime.fromtimestamp(registo.created, timezone.utc).isoformat(),
            "nivel": registo.levelname,
            "componente": "api",
            "mensagem": registo.getMessage(),
            **getattr(registo, "campos", {}),
        }
        if registo.exc_info:
            dados["stack_trace"] = self.formatException(registo.exc_info)
        return json.dumps(dados, ensure_ascii=False)


def configurar_logs() -> None:
    """Logs da API em JSON para stdout. Idempotente (o reload do uvicorn importa outra vez)."""
    if any(isinstance(h.formatter, FormatoJson) for h in log.handlers):
        return
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(FormatoJson())
    log.addHandler(handler)
    log.setLevel(logging.INFO)
    log.propagate = False


def _rota(request: Request) -> str:
    """Modelo da rota que respondeu (`/reportes/{reporte_id}`); sem rota, um só valor.

    Com `include_router(prefix=...)`, a rota guardada no pedido só tem a parte do router
    (`/{reporte_id}`); o prefixo é o que sobra do caminho real depois dessa parte.
    """
    rota = request.scope.get("route")
    modelo = getattr(rota, "path_format", None)
    if modelo is None:
        return "sem_rota"
    caminho = request.scope.get("path", "")
    parametros = {k: str(v) for k, v in request.scope.get("path_params", {}).items()}
    try:
        sufixo = modelo.format(**parametros)
    except (KeyError, IndexError, ValueError):
        return modelo
    if sufixo and not caminho.endswith(sufixo):
        return modelo
    prefixo = caminho[: len(caminho) - len(sufixo)] if sufixo else caminho
    return prefixo + modelo if sufixo else prefixo or modelo


async def middleware_observabilidade(request: Request, call_next):
    recebido = request.headers.get("X-Request-ID", "")
    request.state.request_id = (
        recebido if REQUEST_ID_VALIDO.match(recebido) else str(uuid4())
    )
    inicio = time.perf_counter()
    try:
        resposta = await call_next(request)
    except Exception:
        ERROS.inc()
        resposta = JSONResponse(
            status_code=500,
            content={
                "codigo": "erro_interno",
                "mensagem": "Ocorreu um erro inesperado.",
                "request_id": request.state.request_id,
            },
        )
        duracao = time.perf_counter() - inicio
        _registar(request, 500, duracao, logging.ERROR, exc_info=True)
    else:
        duracao = time.perf_counter() - inicio
        if resposta.status_code >= 500:
            nivel = logging.ERROR
        elif resposta.status_code >= 400:
            nivel = logging.WARNING
        else:
            nivel = logging.INFO
        _registar(request, resposta.status_code, duracao, nivel)
    rota = _rota(request)
    PEDIDOS.labels(request.method, rota, str(resposta.status_code)).inc()
    DURACAO.labels(request.method, rota).observe(duracao)
    resposta.headers["X-Request-ID"] = request.state.request_id
    return resposta


def _registar(
    request: Request, status: int, duracao: float, nivel: int, exc_info: bool = False
) -> None:
    rota = _rota(request)
    if rota in SEM_LOG and status < 500:
        return
    campos = {
        "request_id": request.state.request_id,
        "metodo": request.method,
        "rota": rota,
        "status": status,
        "duracao_ms": round(duracao * 1000, 1),
    }
    # Preenchido por security.utilizador_atual quando o pedido tem credencial válida.
    campos.update(getattr(request.state, "utilizador", {}))
    log.log(nivel, "pedido", extra={"campos": campos}, exc_info=exc_info)
