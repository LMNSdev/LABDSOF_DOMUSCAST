"""Finalize the consolidated migration chain.

Revision ID: 0005_merge_heads
Revises: 0004
Create Date: 2026-11-19
"""
from typing import Sequence


revision: str = "0005_merge_heads"
down_revision: str = "0004"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
