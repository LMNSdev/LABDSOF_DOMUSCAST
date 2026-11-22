"""Alinha a tabela ata com o modelo de dados de 8.3 (US-24)

- `estado_ata` passa a ter os estados de 8.3: a_transcrever, pendente_revisao,
  falhou_transcricao e aprovada. O antigo `rascunho` passa a `pendente_revisao`.
  O estado deixa de ter valor por omissão: quem cria a ata (US-10 ou US-25)
  indica sempre o estado inicial.
- `aprovada_por` regista o administrador que aprovou a ata.
- `reuniao_id` passa a ser único: cada reunião tem no máximo uma ata (1 para 0..1).

Revision ID: 0008
Revises: 0007
Create Date: 2026-11-22
"""
from typing import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "0008"
down_revision: str | None = "0007"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

ESTADOS_NOVOS = ("a_transcrever", "pendente_revisao", "falhou_transcricao", "aprovada")
ESTADOS_ANTIGOS = ("rascunho", "aprovada")


def _trocar_enum(valores: tuple[str, ...], conversao_sql: str) -> None:
    """Recria o tipo `estado_ata` com outros valores, convertendo os dados existentes.

    Recriar o tipo (em vez de `ALTER TYPE ... ADD VALUE`) mantém tudo numa única
    transação: se algum passo falhar, a migração é desfeita por completo.
    """
    op.execute("ALTER TABLE ata ALTER COLUMN estado DROP DEFAULT")
    op.execute("ALTER TYPE estado_ata RENAME TO estado_ata_antigo")
    sa.Enum(*valores, name="estado_ata").create(op.get_bind())
    op.execute(
        f"ALTER TABLE ata ALTER COLUMN estado TYPE estado_ata USING ({conversao_sql})::estado_ata"
    )
    op.execute("DROP TYPE estado_ata_antigo")


def upgrade() -> None:
    _trocar_enum(
        ESTADOS_NOVOS,
        "CASE estado::text WHEN 'rascunho' THEN 'pendente_revisao' ELSE estado::text END",
    )
    op.add_column(
        "ata",
        sa.Column(
            "aprovada_por",
            sa.Integer(),
            sa.ForeignKey("administrador.id", name="fk_ata_aprovada_por"),
            nullable=True,
        ),
    )
    op.create_unique_constraint("uq_ata_reuniao_id", "ata", ["reuniao_id"])


def downgrade() -> None:
    op.drop_constraint("uq_ata_reuniao_id", "ata", type_="unique")
    op.drop_constraint("fk_ata_aprovada_por", "ata", type_="foreignkey")
    op.drop_column("ata", "aprovada_por")
    # Os três estados não aprovados voltam todos a `rascunho`.
    _trocar_enum(
        ESTADOS_ANTIGOS,
        "CASE estado::text WHEN 'aprovada' THEN 'aprovada' ELSE 'rascunho' END",
    )
    op.execute("ALTER TABLE ata ALTER COLUMN estado SET DEFAULT 'rascunho'")
