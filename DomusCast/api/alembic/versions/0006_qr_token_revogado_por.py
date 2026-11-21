"""Adiciona coluna revogado_por ao qr_token (US-20)

Regista o administrador que revogou o QR code (10.2).

Revision ID: 0006
Revises: 0005_merge_heads
Create Date: 2026-11-20
"""
from typing import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "0006"
down_revision: str | None = "0005_merge_heads"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "qr_token",
        sa.Column(
            "revogado_por",
            sa.Integer(),
            sa.ForeignKey("administrador.id", name="fk_qr_token_revogado_por"),
            nullable=True,
        ),
    )


def downgrade() -> None:
    op.drop_constraint("fk_qr_token_revogado_por", "qr_token", type_="foreignkey")
    op.drop_column("qr_token", "revogado_por")
