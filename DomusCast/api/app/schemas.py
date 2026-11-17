from datetime import datetime
from typing import Annotated, Optional
from pydantic import BaseModel, Field, StringConstraints
from .models import EstadoReporte

MAX_FRACOES = 200

NomeObrigatorio = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=200)]


# --- US-01: condomínio, frações e QR codes ---

class CondominioCreate(BaseModel):
    nome: NomeObrigatorio
    nome_admin: NomeObrigatorio
    n_fracoes: int = Field(..., ge=1, le=MAX_FRACOES)


class FracaoOut(BaseModel):
    id: int
    designacao: str

    model_config = {"from_attributes": True}


class FracaoResumo(FracaoOut):
    n_residentes: int


class CondominioCriado(BaseModel):
    id: int
    nome: str
    n_fracoes: int
    credencial_admin: str
    fracoes: list[FracaoOut]


class QrGerado(BaseModel):
    token: str
    link: str
    fracao: str
    criado_em: datetime


# --- US-15: identidade do residente ---

class IdentidadeCreate(BaseModel):
    token: str = Field(..., min_length=1, max_length=256)
    nome: NomeObrigatorio

    model_config = {"extra": "forbid"}


class IdentidadeCriada(BaseModel):
    id: int
    nome: str
    fracao: str
    credencial: str


class ReporteCreate(BaseModel):
    descricao: str = Field(..., min_length=1, max_length=2000)
    foto_url: Optional[str] = None
    idempotency_key: Optional[str] = Field(None, max_length=64)


class ReporteOut(BaseModel):
    id: int
    descricao: str
    foto_url: Optional[str]
    estado: EstadoReporte
    criado_em: datetime
    atualizado_em: datetime

    model_config = {"from_attributes": True}
