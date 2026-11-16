"""US-01: gerar um QR code para uma fração.

O token só é devolvido nesta resposta; a base de dados guarda apenas o hash.
Gerar um novo QR não revoga os anteriores (a revogação é a US-20).
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from .. import models, schemas
from ..database import get_db
from ..security import admin_atual, exigir_admin_do_condominio, gerar_token, hash_token

router = APIRouter()


@router.post("/{fracao_id}/qr", response_model=schemas.QrGerado, status_code=201)
def gerar_qr(
    fracao_id: int,
    admin: models.Administrador = Depends(admin_atual),
    db: Session = Depends(get_db),
):
    fracao = db.get(models.Fracao, fracao_id)
    if fracao is None:
        raise HTTPException(status_code=404, detail="Fração não encontrada.")
    exigir_admin_do_condominio(admin, fracao.condominio_id)

    token = gerar_token()
    qr = models.QrToken(fracao_id=fracao.id, token_hash=hash_token(token))
    db.add(qr)
    db.commit()
    db.refresh(qr)

    return schemas.QrGerado(
        token=token,
        link=f"domuscast://entrar?t={token}",
        fracao=fracao.designacao,
        criado_em=qr.criado_em,
    )
