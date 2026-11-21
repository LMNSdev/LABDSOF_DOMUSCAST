from datetime import datetime, timezone
from typing import Annotated, Optional
from pydantic import (
    AwareDatetime,
    BaseModel,
    ConfigDict,
    Field,
    StringConstraints,
    field_validator,
)
from .models import EstadoReporte, EstadoSyncReuniao

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
    id: int  # US-20: o mesmo id da lista dos ativos, para a app saber qual está no ecrã
    token: str
    link: str
    fracao: str
    criado_em: datetime


class QrAtivo(BaseModel):
    """US-20: QR code ainda válido, sem o token (o servidor só guarda o hash)."""

    id: int
    criado_em: datetime
    n_residentes: int


class QrRevogados(BaseModel):
    revogados: int


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
    # US-23: só na vista do administrador, para mostrar "Residente removido, fração A".
    autor_removido: bool = False


# --- US-13: reuniões ---

LocalReuniao = Annotated[
    str, StringConstraints(strip_whitespace=True, min_length=1, max_length=200)
]


class ReuniaoCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    # AwareDatetime recusa datas sem fuso (a app envia a hora de Portugal com o offset).
    data_hora: AwareDatetime
    local: LocalReuniao

    @field_validator("data_hora")
    @classmethod
    def data_no_futuro(cls, value: datetime) -> datetime:
        # Guardada em UTC: o SQLite dos testes ignora o offset ao gravar.
        value = value.astimezone(timezone.utc)
        if value <= datetime.now(timezone.utc):
            raise ValueError("A reunião tem de ser agendada para o futuro.")
        return value


class ReuniaoOut(BaseModel):
    id: int
    data_hora: datetime
    local: str
    estado_sync: EstadoSyncReuniao
    criado_em: datetime

    model_config = {"from_attributes": True}

    @field_validator("data_hora", "criado_em")
    @classmethod
    def com_fuso(cls, value: datetime) -> datetime:
        # O SQLite devolve datas sem fuso; os valores gravados estão em UTC.
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
