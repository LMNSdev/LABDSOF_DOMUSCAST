from contextlib import asynccontextmanager
from typing import Annotated

from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse, Response
from prometheus_client import CONTENT_TYPE_LATEST, generate_latest
from starlette.exceptions import HTTPException as StarletteHTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from sqlalchemy.exc import OperationalError
from .database import get_db
from .erros import ErroApi, tratar_erro_api
from .observabilidade import configurar_logs, middleware_observabilidade
from .routers import condominios, fracoes, identidades, qr, reportes, reunioes


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield


configurar_logs()

app = FastAPI(title="DomusCast API", version="0.1.0", lifespan=lifespan)

# T-07: request_id (do cabeçalho X-Request-ID, se válido), log JSON e métricas por pedido.
app.middleware("http")(middleware_observabilidade)


def _erro(request: Request, codigo: str, mensagem: str, status_code: int, headers=None):
    return JSONResponse(
        status_code=status_code,
        headers=headers,
        content={
            "codigo": codigo,
            "mensagem": mensagem,
            "request_id": request.state.request_id,
        },
    )


@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    codigos = {
        401: "nao_autenticado",
        403: "sem_permissao",
        404: "nao_encontrado",
        422: "dados_invalidos",
        429: "limite_pedidos",
        503: "servico_indisponivel",
    }
    mensagem = (
        exc.detail
        if isinstance(exc.detail, str)
        else "O pedido não pode ser processado."
    )
    return _erro(
        request,
        codigos.get(exc.status_code, "erro"),
        mensagem,
        exc.status_code,
        exc.headers,
    )


@app.exception_handler(RequestValidationError)
async def request_validation_exception_handler(
    request: Request, _exc: RequestValidationError
):
    return _erro(request, "dados_invalidos", "Dados inválidos.", 422)


app.add_exception_handler(ErroApi, tratar_erro_api)

app.include_router(reportes.router, prefix="/reportes", tags=["reportes"])
app.include_router(condominios.router, prefix="/condominios", tags=["condominios"])
app.include_router(fracoes.router, prefix="/fracoes", tags=["fracoes"])
app.include_router(identidades.router, prefix="/identidades", tags=["identidades"])
app.include_router(qr.router, prefix="/qr", tags=["qr"])
app.include_router(reunioes.router, prefix="/reunioes", tags=["reunioes"])


@app.get("/health", tags=["infra"])
def health(db: Annotated[Session, Depends(get_db)]):
    try:
        db.execute(text("SELECT 1"))
        return {"status": "ok", "db": "ok"}
    except OperationalError as exc:
        raise HTTPException(
            status_code=503,
            detail="A base de dados está temporariamente indisponível.",
            headers={"Retry-After": "5"},
        ) from exc


@app.get("/metrics", tags=["infra"], include_in_schema=False)
def metrics():
    """Métricas Prometheus (8.7). Só na rede interna: o Caddy responde 404 a /metrics."""
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
