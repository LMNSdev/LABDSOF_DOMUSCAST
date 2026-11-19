"""Chave de idempotência única por autor e não em toda a tabela (US-09)

Dois residentes podem gerar a mesma chave; com o unique global o segundo
recebia 500. O índice composto também serve a procura por (autor, chave).

Revision ID: 0004
Revises: 0003
Create Date: 2026-11-18
"""
from typing import Sequence

from alembic import op


revision: str = "0004"
down_revision: str | None = "0003"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

TABELA = "reporte"
UNIQUE_AUTOR = "uq_reporte_autor_idempotency_key"
UNIQUE_GLOBAL = "reporte_idempotency_key_key"
INDICE = "ix_reporte_idempotency_key"


def upgrade() -> None:
    op.drop_index(INDICE, table_name=TABELA)
    op.drop_constraint(UNIQUE_GLOBAL, TABELA, type_="unique")
    op.create_unique_constraint(UNIQUE_AUTOR, TABELA, ["autor_id", "idempotency_key"])


def downgrade() -> None:
    # Falha se já houver a mesma chave em autores diferentes, como deve.
    op.drop_constraint(UNIQUE_AUTOR, TABELA, type_="unique")
    op.create_unique_constraint(UNIQUE_GLOBAL, TABELA, ["idempotency_key"])
    op.create_index(INDICE, TABELA, ["idempotency_key"])
