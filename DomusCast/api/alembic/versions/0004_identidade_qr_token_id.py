"""Adiciona coluna qr_token_id à identidade (US-15)

Revision ID: 0004_identidade_qr_token_id
Revises: 0003
Create Date: 2026-11-18
"""
from typing import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "0004_identidade_qr_token_id"
down_revision: str | None = "0003"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "identidade",
        sa.Column("qr_token_id", sa.Integer(), sa.ForeignKey("qr_token.id"), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("identidade", "qr_token_id")
