"""Adiciona coluna removida_por à identidade (US-23)

Regista o administrador que removeu a identidade.

Revision ID: 0007
Revises: 0006
Create Date: 2026-11-20
"""
from typing import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "0007"
down_revision: str | None = "0006"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "identidade",
        sa.Column(
            "removida_por",
            sa.Integer(),
            sa.ForeignKey("administrador.id", name="fk_identidade_removida_por"),
            nullable=True,
        ),
    )


def downgrade() -> None:
    op.drop_constraint("fk_identidade_removida_por", "identidade", type_="foreignkey")
    op.drop_column("identidade", "removida_por")
