"""US-01: criar condomínio (com frações e primeiro administrador) e consultar frações."""

from fastapi import APIRouter, Depends, Request
from sqlalchemy import func
from sqlalchemy.orm import Session

from .. import models, rate_limit, schemas
from ..database import get_db
from ..security import admin_do_pedido, exigir_admin_do_condominio, gerar_token, hash_token

router = APIRouter()

CRIACOES_POR_IP = 5
JANELA_CRIACOES_S = 3600


def designacao(indice: int) -> str:
    """0 -> A, 25 -> Z, 26 -> AA, 27 -> AB, ... (como as colunas de uma folha de cálculo)."""
    letras = ""
    n = indice + 1
    while n:
        n, resto = divmod(n - 1, 26)
        letras = chr(ord("A") + resto) + letras
    return letras


@router.post("", response_model=schemas.CondominioCriado, status_code=201)
def criar_condominio(
    payload: schemas.CondominioCreate, request: Request, db: Session = Depends(get_db)
):
    rate_limit.verificar(request, "criar_condominio", CRIACOES_POR_IP, JANELA_CRIACOES_S)

    condominio = models.Condominio(nome=payload.nome, n_fracoes=payload.n_fracoes)
    condominio.fracoes = [
        models.Fracao(designacao=designacao(i)) for i in range(payload.n_fracoes)
    ]
    credencial = gerar_token()
    condominio.administradores = [
        models.Administrador(nome=payload.nome_admin, credencial_hash=hash_token(credencial))
    ]
    db.add(condominio)
    db.commit()
    db.refresh(condominio)

    return schemas.CondominioCriado(
        id=condominio.id,
        nome=condominio.nome,
        n_fracoes=condominio.n_fracoes,
        credencial_admin=credencial,
        fracoes=sorted(condominio.fracoes, key=lambda f: f.id),
    )


@router.get("/{condominio_id}/fracoes", response_model=list[schemas.FracaoResumo])
def listar_fracoes(
    condominio_id: int,
    admin: models.Administrador = Depends(admin_do_pedido),
    db: Session = Depends(get_db),
):
    exigir_admin_do_condominio(admin, condominio_id)
    n_residentes = (
        func.count(models.Identidade.id)
        .filter(models.Identidade.removida_em.is_(None))
        .label("n_residentes")
    )
    linhas = (
        db.query(models.Fracao, n_residentes)
        .outerjoin(models.Identidade, models.Identidade.fracao_id == models.Fracao.id)
        .filter(models.Fracao.condominio_id == condominio_id)
        .group_by(models.Fracao.id)
        .order_by(models.Fracao.id)
        .all()
    )
    return [
        schemas.FracaoResumo(id=f.id, designacao=f.designacao, n_residentes=n)
        for f, n in linhas
    ]
