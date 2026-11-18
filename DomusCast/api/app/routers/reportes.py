"""US-02/US-09: reportes de avarias com as regras de visibilidade do autor (10.2).

O administrador vê sempre o nome e a fração do autor. Os residentes nunca recebem
a fração e só recebem o nome quando o autor escolheu mostrá-lo nesse reporte.
"""

from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from .. import models, schemas
from ..database import get_db
from ..security import residente_atual, utilizador_atual

router = APIRouter()


def _vista(
    reporte: models.Reporte, quem: models.Administrador | models.Identidade
) -> schemas.ReporteOut:
    autor = reporte.autor if reporte.autor is not None and reporte.autor.removida_em is None else None
    if isinstance(quem, models.Administrador):
        autor_nome = autor.nome if autor else None
        fracao = autor.fracao.designacao if autor else None
        meu = False
    else:
        autor_nome = autor.nome if autor and reporte.mostrar_nome else None
        fracao = None
        meu = reporte.autor_id == quem.id
    return schemas.ReporteOut(
        id=reporte.id,
        descricao=reporte.descricao,
        foto_url=reporte.foto_url,
        estado=reporte.estado,
        criado_em=reporte.criado_em,
        atualizado_em=reporte.atualizado_em,
        mostrar_nome=reporte.mostrar_nome,
        autor_nome=autor_nome,
        fracao=fracao,
        meu=meu,
    )


def _por_chave(db: Session, residente: models.Identidade, chave: str) -> models.Reporte | None:
    return (
        db.query(models.Reporte)
        .filter(
            models.Reporte.idempotency_key == chave,
            models.Reporte.autor_id == residente.id,
        )
        .first()
    )


@router.post("", response_model=schemas.ReporteOut, status_code=201)
def criar_reporte(
    payload: schemas.ReporteCreate,
    residente: Annotated[models.Identidade, Depends(residente_atual)],
    db: Annotated[Session, Depends(get_db)],
):
    """US-02/US-09: o residente cria um reporte e escolhe se mostra o nome (falso por omissão)."""
    if payload.idempotency_key:
        existente = _por_chave(db, residente, payload.idempotency_key)
        if existente:
            return _vista(existente, residente)

    reporte = models.Reporte(
        condominio_id=residente.fracao.condominio_id,
        autor_id=residente.id,
        descricao=payload.descricao,
        foto_url=payload.foto_url,
        idempotency_key=payload.idempotency_key,
        mostrar_nome=payload.mostrar_nome,
    )
    db.add(reporte)
    try:
        db.commit()
    except IntegrityError:
        # Dois pedidos simultâneos do mesmo autor com a mesma chave: devolve o que ficou gravado.
        db.rollback()
        existente = _por_chave(db, residente, payload.idempotency_key) if payload.idempotency_key else None
        if existente is None:
            raise
        return _vista(existente, residente)
    db.refresh(reporte)
    return _vista(reporte, residente)


@router.get("", response_model=list[schemas.ReporteOut])
def listar_reportes(
    quem: Annotated[models.Administrador | models.Identidade, Depends(utilizador_atual)],
    db: Annotated[Session, Depends(get_db)],
):
    """US-09: reportes do condomínio de quem pede, com o autor visível conforme o papel."""
    condominio_id = (
        quem.condominio_id if isinstance(quem, models.Administrador) else quem.fracao.condominio_id
    )
    reportes = (
        db.query(models.Reporte)
        .filter(models.Reporte.condominio_id == condominio_id)
        .order_by(models.Reporte.criado_em.desc())
        .all()
    )
    return [_vista(r, quem) for r in reportes]
