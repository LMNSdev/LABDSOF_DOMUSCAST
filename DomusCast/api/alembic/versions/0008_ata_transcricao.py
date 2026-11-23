"""Estados de transcrição, origem e unicidade da ata (US-10).

Revision ID: 0008
Revises: 0007
"""

from alembic import op
import sqlalchemy as sa


revision = "0008"
down_revision = "0007"
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    if bind.dialect.name == "postgresql":
        # PostgreSQL não deixa usar um novo valor de enum na transação que o criou.
        with op.get_context().autocommit_block():
            for estado in ("a_transcrever", "pendente_revisao", "falhou_transcricao"):
                op.execute(f"ALTER TYPE estado_ata ADD VALUE IF NOT EXISTS '{estado}'")

    origem = sa.Enum("ia", "manual", name="origem_ata")
    origem.create(bind, checkfirst=True)
    op.add_column("ata", sa.Column("audio_sha256", sa.String(64), nullable=True))
    op.add_column("ata", sa.Column("origem", origem, nullable=False, server_default="ia"))
    op.add_column("ata", sa.Column("aprovada_por", sa.Integer(), nullable=True))
    op.create_foreign_key("fk_ata_aprovada_por", "ata", "administrador", ["aprovada_por"], ["id"])
    op.create_unique_constraint("uq_ata_reuniao", "ata", ["reuniao_id"])
    op.add_column("job", sa.Column("request_id", sa.String(36), nullable=True))


def downgrade() -> None:
    op.drop_column("job", "request_id")
    op.drop_constraint("uq_ata_reuniao", "ata", type_="unique")
    op.drop_constraint("fk_ata_aprovada_por", "ata", type_="foreignkey")
    op.drop_column("ata", "aprovada_por")
    op.drop_column("ata", "origem")
    op.drop_column("ata", "audio_sha256")
    sa.Enum("ia", "manual", name="origem_ata").drop(op.get_bind(), checkfirst=True)
    # Os valores acrescentados a estado_ata mantêm-se no PostgreSQL: removê-los
    # exigiria reescrever o enum e todos os dados existentes.
