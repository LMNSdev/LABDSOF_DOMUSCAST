"""full schema — todas as entidades do modelo de dados (8.3)

Revision ID: 0002
Revises: 0001
Create Date: 2026-10-20
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "0002"
down_revision: Union[str, None] = "0001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # --- condominio ---
    op.create_table(
        "condominio",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("nome", sa.String(200), nullable=False),
        sa.Column("n_fracoes", sa.Integer(), nullable=False),
        sa.Column("criado_em", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
    )

    # --- administrador ---
    op.create_table(
        "administrador",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("condominio_id", sa.Integer(), sa.ForeignKey("condominio.id"), nullable=False),
        sa.Column("nome", sa.String(200), nullable=False),
        sa.Column("credencial_hash", sa.String(128), nullable=False, unique=True),
        sa.Column("criado_em", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("removido_em", sa.DateTime(timezone=True), nullable=True),
    )

    # --- convite_admin ---
    op.create_table(
        "convite_admin",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("condominio_id", sa.Integer(), sa.ForeignKey("condominio.id"), nullable=False),
        sa.Column("codigo_hash", sa.String(128), nullable=False, unique=True),
        sa.Column("criado_por", sa.Integer(), sa.ForeignKey("administrador.id"), nullable=False),
        sa.Column("expira_em", sa.DateTime(timezone=True), nullable=False),
        sa.Column("usado_em", sa.DateTime(timezone=True), nullable=True),
    )

    # --- fracao ---
    op.create_table(
        "fracao",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("condominio_id", sa.Integer(), sa.ForeignKey("condominio.id"), nullable=False),
        sa.Column("designacao", sa.String(100), nullable=False),
    )

    # --- qr_token ---
    op.create_table(
        "qr_token",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("fracao_id", sa.Integer(), sa.ForeignKey("fracao.id"), nullable=False),
        sa.Column("token_hash", sa.String(128), nullable=False, unique=True),
        sa.Column("criado_em", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("revogado_em", sa.DateTime(timezone=True), nullable=True),
    )

    # --- identidade (cria o enum papel_identidade) ---
    op.create_table(
        "identidade",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("fracao_id", sa.Integer(), sa.ForeignKey("fracao.id"), nullable=False),
        sa.Column("nome", sa.String(200), nullable=True),
        sa.Column("nome_normalizado", sa.String(200), nullable=True),
        sa.Column(
            "papel",
            sa.Enum("residente", "comissao", name="papel_identidade"),
            nullable=False,
            server_default="residente",
        ),
        sa.Column("credencial_hash", sa.String(128), nullable=False, unique=True),
        sa.Column("criado_em", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("removida_em", sa.DateTime(timezone=True), nullable=True),
        sa.UniqueConstraint("fracao_id", "nome_normalizado", name="uq_identidade_nome_fracao"),
    )

    # --- reporte: colunas novas (condominio_id e autor_id nullable por compat. com walking skeleton) ---
    op.add_column("reporte", sa.Column("condominio_id", sa.Integer(), sa.ForeignKey("condominio.id"), nullable=True))
    op.add_column("reporte", sa.Column("autor_id", sa.Integer(), sa.ForeignKey("identidade.id"), nullable=True))
    op.add_column("reporte", sa.Column("foto_path", sa.String(500), nullable=True))
    op.add_column("reporte", sa.Column("foto_alt", sa.String(300), nullable=True))
    op.add_column("reporte", sa.Column("mostrar_nome", sa.Boolean(), nullable=False, server_default="false"))
    op.add_column("reporte", sa.Column("duplicado_de_id", sa.Integer(), sa.ForeignKey("reporte.id"), nullable=True))

    # --- reporte_historico (só inserção — nunca update/delete) ---
    op.create_table(
        "reporte_historico",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("reporte_id", sa.Integer(), sa.ForeignKey("reporte.id"), nullable=False),
        sa.Column(
            "estado_anterior",
            sa.Enum("aberto", "em_curso", "resolvido", name="estado_reporte", create_type=False),
            nullable=True,
        ),
        sa.Column(
            "estado_novo",
            sa.Enum("aberto", "em_curso", "resolvido", name="estado_reporte", create_type=False),
            nullable=False,
        ),
        sa.Column("nota", sa.Text(), nullable=True),
        sa.Column("autor_tipo", sa.String(50), nullable=False),
        sa.Column("autor_id", sa.Integer(), nullable=True),
        sa.Column("criado_em", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
    )

    # --- reporte_seguidor (cria o enum tipo_seguidor) ---
    op.create_table(
        "reporte_seguidor",
        sa.Column("reporte_id", sa.Integer(), sa.ForeignKey("reporte.id"), primary_key=True),
        sa.Column("identidade_id", sa.Integer(), sa.ForeignKey("identidade.id"), primary_key=True),
        sa.Column(
            "tipo",
            sa.Enum("autor", "co_reporter", "seguidor", name="tipo_seguidor"),
            nullable=False,
        ),
    )

    # --- aviso ---
    op.create_table(
        "aviso",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("condominio_id", sa.Integer(), sa.ForeignKey("condominio.id"), nullable=False),
        sa.Column("reporte_id", sa.Integer(), sa.ForeignKey("reporte.id"), nullable=True),
        sa.Column("titulo", sa.String(200), nullable=False),
        sa.Column("texto", sa.Text(), nullable=False),
        sa.Column("local", sa.String(200), nullable=True),
        sa.Column("publicado_em", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("arquivado_em", sa.DateTime(timezone=True), nullable=True),
    )

    # --- reuniao (cria o enum estado_sync_reuniao) ---
    op.create_table(
        "reuniao",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("condominio_id", sa.Integer(), sa.ForeignKey("condominio.id"), nullable=False),
        sa.Column("data_hora", sa.DateTime(timezone=True), nullable=False),
        sa.Column("local", sa.String(300), nullable=True),
        sa.Column("calendario_externo_id", sa.String(200), nullable=True),
        sa.Column(
            "estado_sync",
            sa.Enum("pendente", "sincronizada", "alternativo", "degradado", name="estado_sync_reuniao"),
            nullable=False,
            server_default="pendente",
        ),
        sa.Column("criado_em", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
    )

    # --- ata (cria o enum estado_ata) ---
    op.create_table(
        "ata",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("reuniao_id", sa.Integer(), sa.ForeignKey("reuniao.id"), nullable=False),
        sa.Column("audio_path", sa.String(500), nullable=True),
        sa.Column("transcricao", sa.Text(), nullable=True),
        sa.Column("rascunho", sa.Text(), nullable=True),
        sa.Column("texto_aprovado", sa.Text(), nullable=True),
        sa.Column(
            "estado",
            sa.Enum("rascunho", "aprovada", name="estado_ata"),
            nullable=False,
            server_default="rascunho",
        ),
        sa.Column("aprovada_em", sa.DateTime(timezone=True), nullable=True),
    )

    # --- job (cria o enum estado_job; outbox consumido pelo Worker) ---
    op.create_table(
        "job",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("tipo", sa.String(100), nullable=False),
        sa.Column("chave_idempotencia", sa.String(128), nullable=False, unique=True),
        sa.Column("payload", sa.Text(), nullable=True),
        sa.Column(
            "estado",
            sa.Enum("pendente", "em_curso", "concluido", "falhou", name="estado_job"),
            nullable=False,
            server_default="pendente",
        ),
        sa.Column("tentativas", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("proxima_tentativa_em", sa.DateTime(timezone=True), nullable=True),
        sa.Column("erro", sa.Text(), nullable=True),
        sa.Column("criado_em", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
    )
    op.create_index("ix_job_estado_proxima", "job", ["estado", "proxima_tentativa_em"])


def downgrade() -> None:
    op.drop_index("ix_job_estado_proxima", table_name="job")
    op.drop_table("job")
    op.drop_table("ata")
    op.drop_table("reuniao")
    op.drop_table("aviso")
    op.drop_table("reporte_seguidor")
    op.drop_table("reporte_historico")
    op.drop_column("reporte", "duplicado_de_id")
    op.drop_column("reporte", "mostrar_nome")
    op.drop_column("reporte", "foto_alt")
    op.drop_column("reporte", "foto_path")
    op.drop_column("reporte", "autor_id")
    op.drop_column("reporte", "condominio_id")
    op.drop_table("identidade")
    op.drop_table("qr_token")
    op.drop_table("fracao")
    op.drop_table("convite_admin")
    op.drop_table("administrador")
    op.drop_table("condominio")
    op.execute("DROP TYPE IF EXISTS estado_job")
    op.execute("DROP TYPE IF EXISTS estado_ata")
    op.execute("DROP TYPE IF EXISTS estado_sync_reuniao")
    op.execute("DROP TYPE IF EXISTS tipo_seguidor")
    op.execute("DROP TYPE IF EXISTS papel_identidade")
