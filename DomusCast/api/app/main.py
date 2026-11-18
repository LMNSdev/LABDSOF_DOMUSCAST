from contextlib import asynccontextmanager
from typing import Annotated

from fastapi import FastAPI, Depends
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from sqlalchemy import text
from sqlalchemy.exc import OperationalError
from .database import get_db
from .erros import ErroApi, tratar_erro_api
from .routers import condominios, fracoes, identidades, reportes


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield


app = FastAPI(title="DomusCast API", version="0.1.0", lifespan=lifespan)
app.add_exception_handler(ErroApi, tratar_erro_api)

app.include_router(reportes.router, prefix="/reportes", tags=["reportes"])
app.include_router(condominios.router, prefix="/condominios", tags=["condominios"])
app.include_router(fracoes.router, prefix="/fracoes", tags=["fracoes"])
app.include_router(identidades.router, prefix="/identidades", tags=["identidades"])


@app.get("/health", tags=["infra"])
def health(db: Annotated[Session, Depends(get_db)]):
    try:
        db.execute(text("SELECT 1"))
        return {"status": "ok", "db": "ok"}
    except OperationalError:
        return JSONResponse(
            status_code=503,
            content={"status": "degraded", "db": "unreachable"},
        )
