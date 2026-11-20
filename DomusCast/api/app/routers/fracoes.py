"""QR codes de uma fração: gerar (US-01), listar os ativos e revogar todos (US-20).

O token só é devolvido quando é gerado; a base de dados guarda apenas o hash.
Gerar um novo QR não revoga os anteriores; revogar é uma ação própria (US-20).
"""

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
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
        id=qr.id,
        token=token,
        link=f"domuscast://entrar?t={token}",
        fracao=fracao.designacao,
        criado_em=qr.criado_em,
    )


@router.get("/{fracao_id}/qr", response_model=list[schemas.QrAtivo])
def listar_qr(
    fracao_id: int,
    admin: models.Administrador = Depends(admin_do_pedido),
    db: Session = Depends(get_db),
):
    """QR codes ativos, com o nº de residentes que entraram com cada um e ainda têm acesso."""
    fracao = _fracao_do_admin(db, admin, fracao_id)
    n_residentes = (
        func.count(models.Identidade.id)
        .filter(models.Identidade.removida_em.is_(None))
        .label("n_residentes")
    )
    linhas = (
        db.query(models.QrToken, n_residentes)
        .outerjoin(models.Identidade, models.Identidade.qr_token_id == models.QrToken.id)
        .filter(models.QrToken.fracao_id == fracao.id, models.QrToken.revogado_em.is_(None))
        .group_by(models.QrToken.id)
        .order_by(models.QrToken.criado_em, models.QrToken.id)
        .all()
    )
    return [
        schemas.QrAtivo(id=qr.id, criado_em=qr.criado_em, n_residentes=n) for qr, n in linhas
    ]


@router.post("/{fracao_id}/qr/revogar", response_model=schemas.QrRevogados)
def revogar_todos_qr(
    fracao_id: int,
    admin: models.Administrador = Depends(admin_do_pedido),
    db: Session = Depends(get_db),
):
    """Revoga todos os QR codes ativos da fração; as identidades já criadas mantêm-se."""
    fracao = _fracao_do_admin(db, admin, fracao_id)
    ativos = (
        db.query(models.QrToken)
        .filter(models.QrToken.fracao_id == fracao.id, models.QrToken.revogado_em.is_(None))
        .all()
    )
    agora = datetime.now(timezone.utc)
    for qr in ativos:
        qr.revogado_em = agora
        qr.revogado_por = admin.id
    db.commit()
    return schemas.QrRevogados(revogados=len(ativos))
