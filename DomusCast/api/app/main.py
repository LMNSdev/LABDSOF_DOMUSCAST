from contextlib import asynccontextmanager
from fastapi import FastAPI, Depends
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from sqlalchemy import text
from sqlalchemy.exc import OperationalError
from .database import get_db
from .routers import reportes


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield


app = FastAPI(title="DomusCast API", version="0.1.0", lifespan=lifespan)

app.include_router(reportes.router, prefix="/reportes", tags=["reportes"])


@app.get("/health", tags=["infra"])
def health(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
        return {"status": "ok", "db": "ok"}
    except OperationalError:
        return JSONResponse(
            status_code=503,
            content={"status": "degraded", "db": "unreachable"},
        )
