import enum
from sqlalchemy import Column, Integer, String, Text, DateTime, Enum, func
from .database import Base


class EstadoReporte(str, enum.Enum):
    aberto = "aberto"
    em_curso = "em_curso"
    resolvido = "resolvido"


class Reporte(Base):
    __tablename__ = "reporte"

    id = Column(Integer, primary_key=True)
    descricao = Column(Text, nullable=False)
    foto_url = Column(String(500), nullable=True)
    estado = Column(
        Enum(EstadoReporte, name="estado_reporte"),
        default=EstadoReporte.aberto,
        server_default="aberto",
        nullable=False,
    )
    idempotency_key = Column(String(64), unique=True, nullable=True, index=True)
    criado_em = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    atualizado_em = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
