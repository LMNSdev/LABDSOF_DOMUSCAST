import enum
from sqlalchemy import (
    Boolean, Column, DateTime, Enum, ForeignKey,
    Integer, String, Text, UniqueConstraint, func,
)
from sqlalchemy.orm import relationship
from .database import Base


# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

class EstadoReporte(str, enum.Enum):
    aberto = "aberto"
    em_curso = "em_curso"
    resolvido = "resolvido"


class PapelIdentidade(str, enum.Enum):
    residente = "residente"
    comissao = "comissao"


class TipoSeguidor(str, enum.Enum):
    autor = "autor"
    co_reporter = "co_reporter"
    seguidor = "seguidor"


class EstadoSyncReuniao(str, enum.Enum):
    pendente = "pendente"
    sincronizada = "sincronizada"
    alternativo = "alternativo"
    degradado = "degradado"


class EstadoAta(str, enum.Enum):
    rascunho = "rascunho"
    aprovada = "aprovada"


class EstadoJob(str, enum.Enum):
    pendente = "pendente"
    em_curso = "em_curso"
    concluido = "concluido"
    falhou = "falhou"


# ---------------------------------------------------------------------------
# Models
# ---------------------------------------------------------------------------

class Condominio(Base):
    __tablename__ = "condominio"

    id = Column(Integer, primary_key=True)
    nome = Column(String(200), nullable=False)
    n_fracoes = Column(Integer, nullable=False)
    criado_em = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    administradores = relationship("Administrador", back_populates="condominio")
    fracoes = relationship("Fracao", back_populates="condominio")
    reportes = relationship("Reporte", back_populates="condominio")
    avisos = relationship("Aviso", back_populates="condominio")
    reunioes = relationship("Reuniao", back_populates="condominio")


class Administrador(Base):
    __tablename__ = "administrador"

    id = Column(Integer, primary_key=True)
    condominio_id = Column(Integer, ForeignKey("condominio.id"), nullable=False)
    nome = Column(String(200), nullable=False)
    credencial_hash = Column(String(128), nullable=False, unique=True)
    criado_em = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    removido_em = Column(DateTime(timezone=True), nullable=True)

    condominio = relationship("Condominio", back_populates="administradores")
    convites = relationship("ConviteAdmin", back_populates="criado_por_admin", foreign_keys="ConviteAdmin.criado_por")


class ConviteAdmin(Base):
    __tablename__ = "convite_admin"

    id = Column(Integer, primary_key=True)
    condominio_id = Column(Integer, ForeignKey("condominio.id"), nullable=False)
    codigo_hash = Column(String(128), nullable=False, unique=True)
    criado_por = Column(Integer, ForeignKey("administrador.id"), nullable=False)
    expira_em = Column(DateTime(timezone=True), nullable=False)
    usado_em = Column(DateTime(timezone=True), nullable=True)

    criado_por_admin = relationship("Administrador", back_populates="convites", foreign_keys=[criado_por])


class Fracao(Base):
    __tablename__ = "fracao"

    id = Column(Integer, primary_key=True)
    condominio_id = Column(Integer, ForeignKey("condominio.id"), nullable=False)
    designacao = Column(String(100), nullable=False)

    condominio = relationship("Condominio", back_populates="fracoes")
    qr_tokens = relationship("QrToken", back_populates="fracao")
    identidades = relationship("Identidade", back_populates="fracao")


class QrToken(Base):
    __tablename__ = "qr_token"

    id = Column(Integer, primary_key=True)
    fracao_id = Column(Integer, ForeignKey("fracao.id"), nullable=False)
    token_hash = Column(String(128), nullable=False, unique=True)
    criado_em = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    revogado_em = Column(DateTime(timezone=True), nullable=True)

    fracao = relationship("Fracao", back_populates="qr_tokens")


class Identidade(Base):
    __tablename__ = "identidade"

    id = Column(Integer, primary_key=True)
    fracao_id = Column(Integer, ForeignKey("fracao.id"), nullable=False)
    nome = Column(String(200), nullable=True)           # apagado ao remover identidade (US-09)
    nome_normalizado = Column(String(200), nullable=True)
    papel = Column(
        Enum(PapelIdentidade, name="papel_identidade"),
        nullable=False,
        server_default="residente",
    )
    credencial_hash = Column(String(128), nullable=False, unique=True)
    criado_em = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    removida_em = Column(DateTime(timezone=True), nullable=True)

    fracao = relationship("Fracao", back_populates="identidades")
    reportes = relationship("Reporte", back_populates="autor")
    seguidores = relationship("ReporteSeguidor", back_populates="identidade")

    __table_args__ = (
        UniqueConstraint("fracao_id", "nome_normalizado", name="uq_identidade_nome_fracao"),
    )


class Reporte(Base):
    __tablename__ = "reporte"

    id = Column(Integer, primary_key=True)
    condominio_id = Column(Integer, ForeignKey("condominio.id"), nullable=True)  # NOT NULL a partir de Sprint B
    autor_id = Column(Integer, ForeignKey("identidade.id"), nullable=True)       # NOT NULL a partir de Sprint B
    descricao = Column(Text, nullable=False)
    foto_url = Column(String(500), nullable=True)        # walking skeleton — substituído por foto_path
    foto_path = Column(String(500), nullable=True)
    foto_alt = Column(String(300), nullable=True)
    mostrar_nome = Column(Boolean, nullable=False, server_default="false")
    estado = Column(
        Enum(EstadoReporte, name="estado_reporte"),
        nullable=False,
        server_default="aberto",
    )
    duplicado_de_id = Column(Integer, ForeignKey("reporte.id"), nullable=True)
    idempotency_key = Column(String(64), unique=True, nullable=True, index=True)
    criado_em = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    atualizado_em = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    condominio = relationship("Condominio", back_populates="reportes")
    autor = relationship("Identidade", back_populates="reportes")
    duplicado_de = relationship("Reporte", remote_side="Reporte.id")
    historico = relationship("ReporteHistorico", back_populates="reporte")
    seguidores = relationship("ReporteSeguidor", back_populates="reporte")
    avisos = relationship("Aviso", back_populates="reporte")


class ReporteHistorico(Base):
    __tablename__ = "reporte_historico"

    id = Column(Integer, primary_key=True)
    reporte_id = Column(Integer, ForeignKey("reporte.id"), nullable=False)
    estado_anterior = Column(Enum(EstadoReporte, name="estado_reporte"), nullable=True)
    estado_novo = Column(Enum(EstadoReporte, name="estado_reporte"), nullable=False)
    nota = Column(Text, nullable=True)
    autor_tipo = Column(String(50), nullable=False)  # "administrador" | "sistema"
    autor_id = Column(Integer, nullable=True)         # id do administrador que fez a mudança
    criado_em = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    reporte = relationship("Reporte", back_populates="historico")


class ReporteSeguidor(Base):
    __tablename__ = "reporte_seguidor"

    reporte_id = Column(Integer, ForeignKey("reporte.id"), primary_key=True)
    identidade_id = Column(Integer, ForeignKey("identidade.id"), primary_key=True)
    tipo = Column(Enum(TipoSeguidor, name="tipo_seguidor"), nullable=False)

    reporte = relationship("Reporte", back_populates="seguidores")
    identidade = relationship("Identidade", back_populates="seguidores")


class Aviso(Base):
    __tablename__ = "aviso"

    id = Column(Integer, primary_key=True)
    condominio_id = Column(Integer, ForeignKey("condominio.id"), nullable=False)
    reporte_id = Column(Integer, ForeignKey("reporte.id"), nullable=True)
    titulo = Column(String(200), nullable=False)
    texto = Column(Text, nullable=False)
    local = Column(String(200), nullable=True)
    publicado_em = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    arquivado_em = Column(DateTime(timezone=True), nullable=True)

    condominio = relationship("Condominio", back_populates="avisos")
    reporte = relationship("Reporte", back_populates="avisos")


class Reuniao(Base):
    __tablename__ = "reuniao"

    id = Column(Integer, primary_key=True)
    condominio_id = Column(Integer, ForeignKey("condominio.id"), nullable=False)
    data_hora = Column(DateTime(timezone=True), nullable=False)
    local = Column(String(300), nullable=True)
    calendario_externo_id = Column(String(200), nullable=True)
    estado_sync = Column(
        Enum(EstadoSyncReuniao, name="estado_sync_reuniao"),
        nullable=False,
        server_default="pendente",
    )
    criado_em = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    condominio = relationship("Condominio", back_populates="reunioes")
    atas = relationship("Ata", back_populates="reuniao")


class Ata(Base):
    __tablename__ = "ata"

    id = Column(Integer, primary_key=True)
    reuniao_id = Column(Integer, ForeignKey("reuniao.id"), nullable=False)
    audio_path = Column(String(500), nullable=True)
    transcricao = Column(Text, nullable=True)
    rascunho = Column(Text, nullable=True)
    texto_aprovado = Column(Text, nullable=True)
    estado = Column(
        Enum(EstadoAta, name="estado_ata"),
        nullable=False,
        server_default="rascunho",
    )
    aprovada_em = Column(DateTime(timezone=True), nullable=True)

    reuniao = relationship("Reuniao", back_populates="atas")


class Job(Base):
    __tablename__ = "job"

    id = Column(Integer, primary_key=True)
    tipo = Column(String(100), nullable=False)
    chave_idempotencia = Column(String(128), nullable=False, unique=True)
    payload = Column(Text, nullable=True)
    estado = Column(
        Enum(EstadoJob, name="estado_job"),
        nullable=False,
        server_default="pendente",
    )
    tentativas = Column(Integer, nullable=False, server_default="0")
    proxima_tentativa_em = Column(DateTime(timezone=True), nullable=True)
    erro = Column(Text, nullable=True)
    criado_em = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
