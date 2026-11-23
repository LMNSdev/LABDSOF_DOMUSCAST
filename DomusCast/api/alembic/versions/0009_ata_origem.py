"""Origem da ata: preparada por IA ou escrita manualmente (US-25)

- `origem` (`ia` ou `manual`) fica guardada para a app indicar, mesmo depois de
  publicada, que a ata é manual e não gerada por IA (8.3).
- As atas que já existem só podem ter vindo da US-10, por isso ficam com `ia`.
- Como o `estado` na 0008, a coluna não tem valor por omissão: quem cria a ata
  (US-10 ou US-25) indica sempre a origem.

Revision ID: 0009
Revises: 0008
Create Date: 2026-11-24
"""
from typing import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "0009"
down_revision: str | None = "0008"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

origem_ata = sa.Enum("ia", "manual", name="origem_ata")


def upgrade() -> None:
    origem_ata.create(op.get_bind())
    # O valor por omissão só serve para preencher as linhas existentes;
    # é retirado logo a seguir, na mesma transação.
    op.add_column(
        "ata",
        sa.Column("origem", origem_ata, nullable=False, server_default="ia"),
    )
    op.alter_column("ata", "origem", server_default=None)


def downgrade() -> None:
    op.drop_column("ata", "origem")
    origem_ata.drop(op.get_bind())
