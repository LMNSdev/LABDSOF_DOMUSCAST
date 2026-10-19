from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field
from .models import EstadoReporte


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
