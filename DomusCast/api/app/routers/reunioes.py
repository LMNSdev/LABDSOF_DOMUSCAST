"""US-13: o administrador agenda reuniões; administrador e residentes consultam-nas.

Criar a reunião enfileira o job `publicar_calendario` na mesma transação (outbox,
8.5 e ADR-005): a publicação no calendário externo é feita depois pelo Worker
(US-28), e a reunião fica guardada mesmo que essa publicação falhe.
"""

import json
from datetime import datetime, timezone
from typing import Annotated
from zoneinfo import ZoneInfo

from fastapi import APIRouter, Depends, HTTPException
from pydantic import AwareDatetime
from sqlalchemy.exc import OperationalError
from sqlalchemy.orm import Session

from .. import models, schemas
from ..database import get_db
from ..security import admin_do_pedido, utilizador_atual

router = APIRouter()

FUSO = ZoneInfo("Europe/Lisbon")
JOB_PUBLICAR = "publicar_calendario"


def _indisponivel() -> HTTPException:
    return HTTPException(
        status_code=503,
        detail="A base de dados está temporariamente indisponível.",
        headers={"Retry-After": "5"},
    )


def _condominio_de(quem: models.Administrador | models.Identidade) -> int:
    if isinstance(quem, models.Administrador):
        return quem.condominio_id
    return quem.fracao.condominio_id


@router.post("", response_model=schemas.ReuniaoOut, status_code=201)
def criar_reuniao(
    dados: schemas.ReuniaoCreate,
    admin: Annotated[models.Administrador, Depends(admin_do_pedido)],
    db: Annotated[Session, Depends(get_db)],
):
    """US-13: agenda uma reunião no futuro, com a publicação no calendário pendente."""
    reuniao = models.Reuniao(
        condominio_id=admin.condominio_id,
        data_hora=dados.data_hora,
        local=dados.local,
        estado_sync=models.EstadoSyncReuniao.pendente,
    )
    try:
        db.add(reuniao)
        db.flush()
        db.add(
            models.Job(
                tipo=JOB_PUBLICAR,
                chave_idempotencia=f"{JOB_PUBLICAR}:{reuniao.id}",
                payload=json.dumps({"reuniao_id": reuniao.id}),
            )
        )
        db.commit()
    except OperationalError as exc:
        db.rollback()
        raise _indisponivel() from exc
    db.refresh(reuniao)
    return reuniao


@router.get("", response_model=list[schemas.ReuniaoOut])
def listar_reunioes(
    quem: Annotated[models.Administrador | models.Identidade, Depends(utilizador_atual)],
    db: Annotated[Session, Depends(get_db)],
    desde: AwareDatetime | None = None,
    incluir_passadas: bool = False,
):
    """US-13: reuniões do condomínio de quem pede, pela ordem da data.

    Sem filtros, as de hoje em diante (dia de Portugal continental). O admin
    usa `incluir_passadas` para anexar o áudio após a assembleia. Com `desde`,
    as criadas ou alteradas desde essa data (US-28).
    """
    consulta = db.query(models.Reuniao).filter(
        models.Reuniao.condominio_id == _condominio_de(quem)
    )
    if incluir_passadas and not isinstance(quem, models.Administrador):
        raise HTTPException(status_code=403, detail="Só o administrador pode consultar reuniões passadas.")
    if desde is None and not incluir_passadas:
        hoje = datetime.now(FUSO).replace(hour=0, minute=0, second=0, microsecond=0)
        consulta = consulta.filter(models.Reuniao.data_hora >= hoje.astimezone(timezone.utc))
    elif desde is not None:
        consulta = consulta.filter(models.Reuniao.atualizado_em >= desde.astimezone(timezone.utc))
    try:
        return consulta.order_by(models.Reuniao.data_hora, models.Reuniao.id).all()
    except OperationalError as exc:
        raise _indisponivel() from exc
