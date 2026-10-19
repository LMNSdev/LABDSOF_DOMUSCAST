"""initial schema - tabela reporte

Revision ID: 0001
Revises:
Create Date: 2026-10-18

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "0001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "reporte",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("descricao", sa.Text(), nullable=False),
        sa.Column("foto_url", sa.String(500), nullable=True),
        sa.Column(
            "estado",
            sa.Enum("aberto", "em_curso", "resolvido", name="estado_reporte"),
            nullable=False,
            server_default="aberto",
        ),
        sa.Column("idempotency_key", sa.String(64), unique=True, nullable=True),
        sa.Column(
            "criado_em",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "atualizado_em",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
    )
    op.create_index("ix_reporte_idempotency_key", "reporte", ["idempotency_key"])


def downgrade() -> None:
    op.drop_index("ix_reporte_idempotency_key", table_name="reporte")
    op.drop_table("reporte")
    op.execute("DROP TYPE IF EXISTS estado_reporte")
