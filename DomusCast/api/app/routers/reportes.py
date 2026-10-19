from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from .. import models, schemas
from ..database import get_db

router = APIRouter()


@router.post("", response_model=schemas.ReporteOut, status_code=201)
def criar_reporte(payload: schemas.ReporteCreate, db: Session = Depends(get_db)):
    if payload.idempotency_key:
        existing = (
            db.query(models.Reporte)
            .filter(models.Reporte.idempotency_key == payload.idempotency_key)
            .first()
        )
        if existing:
            return existing

    reporte = models.Reporte(
        descricao=payload.descricao,
        foto_url=payload.foto_url,
        idempotency_key=payload.idempotency_key,
    )
    db.add(reporte)
    db.commit()
    db.refresh(reporte)
    return reporte


@router.get("", response_model=list[schemas.ReporteOut])
def listar_reportes(db: Session = Depends(get_db)):
    return db.query(models.Reporte).order_by(models.Reporte.criado_em.desc()).all()
