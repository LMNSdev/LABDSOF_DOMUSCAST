"""US-20: revogar um QR code específico, escolhido na lista dos ativos da fração."""

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from .. import models, schemas
from ..database import get_db
from ..security import admin_do_pedido

router = APIRouter()


@router.post("/{qr_id}/revogar", response_model=schemas.QrRevogados)
def revogar_qr(
    qr_id: int,
    admin: models.Administrador = Depends(admin_do_pedido),
    db: Session = Depends(get_db),
):
    """404 se não existir, já foi revogado ou é de outro condomínio (não revela qual).

    Um só UPDATE condicional: numa revogação em simultâneo, a segunda recebe 404 e
    não sobrescreve quem revogou primeiro (regra 10.2).
    """
    do_condominio = db.query(models.Fracao.id).filter(
        models.Fracao.condominio_id == admin.condominio_id
    )
    n = (
        db.query(models.QrToken)
        .filter(
            models.QrToken.id == qr_id,
            models.QrToken.revogado_em.is_(None),
            models.QrToken.fracao_id.in_(do_condominio),
        )
        .update(
            {"revogado_em": datetime.now(timezone.utc), "revogado_por": admin.id},
            synchronize_session=False,
        )
    )
    if n == 0:
        raise HTTPException(status_code=404, detail="QR code não encontrado.")
    db.commit()
    return schemas.QrRevogados(revogados=1)
