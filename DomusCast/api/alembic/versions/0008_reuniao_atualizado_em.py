"""Adiciona atualizado_em à reunião (US-28)

O Worker muda o estado_sync de reuniões já criadas. GET /reunioes?desde= passa a
filtrar por esta coluna, para a app ver essas mudanças.

Revision ID: 0008
Revises: 0007
Create Date: 2026-11-24
"""
from typing import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "0008"
down_revision: str | None = "0007"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "reuniao",
        sa.Column(
            "atualizado_em",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
    )
    # As reuniões existentes não mudaram desde que foram criadas.
    op.execute("UPDATE reuniao SET atualizado_em = criado_em")


def downgrade() -> None:
    op.drop_column("reuniao", "atualizado_em")
