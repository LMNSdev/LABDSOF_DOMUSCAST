from datetime import datetime
from typing import Annotated, Optional
from pydantic import BaseModel, ConfigDict, Field, StringConstraints, field_validator
from .models import EstadoReporte

MAX_FRACOES = 200

NomeObrigatorio = Annotated[
    str, StringConstraints(strip_whitespace=True, min_length=1, max_length=200)
]


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


class IdentidadeResumo(BaseModel):
    """US-23: residente ativo da fração, como o administrador o vê."""

    id: int
    nome: str
    criado_em: datetime


class ReporteCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    descricao: str = Field(..., min_length=1, max_length=2000)
    foto_alt: Optional[str] = Field(None, max_length=300)
    mostrar_nome: bool = False

    @field_validator("foto_alt")
    @classmethod
    def normalizar_foto_alt(cls, value: str | None) -> str | None:
        if value is None:
            return None
        value = value.strip()
        if not value:
            raise ValueError("A descrição alternativa não pode estar vazia.")
        return value

    @field_validator("descricao")
    @classmethod
    def descricao_nao_pode_ser_vazia(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("A descrição é obrigatória.")
        return value


class ReporteOut(BaseModel):
    id: int
    descricao: str
    foto_url: Optional[str] = None
    estado: EstadoReporte
    criado_em: datetime
    atualizado_em: datetime
    mostrar_nome: bool = False
    autor_nome: Optional[str] = None
    fracao: Optional[str] = None
    meu: bool = False
