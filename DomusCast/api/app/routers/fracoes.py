"""Uma fração: gerar QR code (US-01) e listar os residentes (US-23).

O token só é devolvido nesta resposta; a base de dados guarda apenas o hash.
Gerar um novo QR não revoga os anteriores (a revogação é a US-20).
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from .. import models, schemas
from ..database import get_db
from ..security import (
    admin_atual,
    admin_do_pedido,
    exigir_admin_do_condominio,
    gerar_token,
    hash_token,
)

router = APIRouter()


def _fracao_do_admin(db: Session, admin: models.Administrador, fracao_id: int) -> models.Fracao:
    """Fração do condomínio do administrador; 404 se não existir ou for de outro condomínio."""
    fracao = db.get(models.Fracao, fracao_id)
    if fracao is None or fracao.condominio_id != admin.condominio_id:
        raise HTTPException(status_code=404, detail="Fração não encontrada.")
    return fracao


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


@router.get("/{fracao_id}/identidades", response_model=list[schemas.IdentidadeResumo])
def listar_identidades(
    fracao_id: int,
    admin: models.Administrador = Depends(admin_do_pedido),
    db: Session = Depends(get_db),
):
    """Residentes ativos da fração (nome e data de entrada), para o administrador remover quem saiu."""
    fracao = _fracao_do_admin(db, admin, fracao_id)
    ativas = (
        db.query(models.Identidade)
        .filter(models.Identidade.fracao_id == fracao.id, models.Identidade.removida_em.is_(None))
        .order_by(models.Identidade.criado_em, models.Identidade.id)
        .all()
    )
    return [
        schemas.IdentidadeResumo(id=i.id, nome=i.nome, criado_em=i.criado_em) for i in ativas
    ]
