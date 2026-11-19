"""Merge idempotency and QR identity migration branches.

Revision ID: 0005_merge_heads
Revises: 0004, 0004_identidade_qr_token_id
Create Date: 2026-11-19
"""
from typing import Sequence


revision: str = "0005_merge_heads"
down_revision: tuple[str, str] = ("0004", "0004_identidade_qr_token_id")
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
