"""idempotência de reporte por autor

Revision ID: 0003
Revises: 0002
Create Date: 2026-11-17
"""

from typing import Sequence, Union

from alembic import op

revision: str = "0003"
down_revision: Union[str, None] = "0002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.drop_constraint("reporte_idempotency_key_key", "reporte", type_="unique")
    op.create_unique_constraint(
        "uq_reporte_autor_idempotency_key", "reporte", ["autor_id", "idempotency_key"]
    )


def downgrade() -> None:
    op.drop_constraint("uq_reporte_autor_idempotency_key", "reporte", type_="unique")
    op.create_unique_constraint(
        "reporte_idempotency_key_key", "reporte", ["idempotency_key"]
    )
