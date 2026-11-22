"""US-24: o administrador revê, edita e aprova a ata; os residentes só veem a ata aprovada.

A ata nasce na US-10 (upload do áudio e Worker) ou na US-25 (ata manual).

- `GET /reunioes/{id}/ata`: completar na US-10; minimo implementado para US-24.
- `PUT /reunioes/{id}/ata`: guarda o rascunho editado, sem o publicar.
- `POST /reunioes/{id}/ata/aprovar`: publica o rascunho como texto aprovado,
  regista quem aprovou e apaga áudio, transcrição e rascunho.

Estados: só uma ata `pendente_revisao` pode ser editada ou aprovada.
As escritas são UPDATEs condicionais ao estado, para dois pedidos em simultâneo
(ex.: guardar e aprovar) nunca deixarem a ata num estado misto.
"""

from datetime import datetime, timezone
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy import func
from sqlalchemy.exc import OperationalError
from sqlalchemy.orm import Session

from .. import models, schemas
from ..atas import apagar_audio
from ..database import get_db
from ..erros import ErroApi
from ..security import admin_do_pedido, utilizador_atual
from .reunioes import _condominio_de, _indisponivel

router = APIRouter()

PENDENTE = models.EstadoAta.pendente_revisao


def _reuniao_do_condominio(db: Session, condominio_id: int, reuniao_id: int) -> models.Reuniao:
    """404 se a reunião não existir ou for de outro condomínio (não revela qual, 8.4)."""
    reuniao = (
        db.query(models.Reuniao)
        .filter(
            models.Reuniao.id == reuniao_id,
            models.Reuniao.condominio_id == condominio_id,
        )
        .first()
    )
    if reuniao is None:
        raise ErroApi(404, "reuniao_nao_encontrada", "Reunião não encontrada.")
    return reuniao


def _sem_ata() -> ErroApi:
    return ErroApi(404, "ata_inexistente", "Esta reunião ainda não tem ata.")


def _ata_do_admin(db: Session, admin: models.Administrador, reuniao_id: int) -> models.Ata:
    ata = _reuniao_do_condominio(db, admin.condominio_id, reuniao_id).ata
    if ata is None:
        raise _sem_ata()
    return ata


def _conflito(estado: models.EstadoAta) -> ErroApi:
    """409 para uma ata que não pode ser editada ou aprovada.

    `falhou_transcricao` (e uma ata pendente sem texto) dão `ata_sem_rascunho`
    """
    if estado == models.EstadoAta.aprovada:
        return ErroApi(409, "ata_ja_aprovada", "Esta ata já foi aprovada e publicada.")
    if estado == models.EstadoAta.a_transcrever:
        return ErroApi(
            409, "ata_em_processamento", "A transcrição ainda está em curso. Tente mais tarde."
        )
    return ErroApi(409, "ata_sem_rascunho", "Esta ata não tem rascunho para rever.")


@router.get(
    "/{reuniao_id}/ata",
    response_model=schemas.AtaAdminOut | schemas.AtaPublicaOut,
)
def obter_ata(
    reuniao_id: int,
    quem: Annotated[models.Administrador | models.Identidade, Depends(utilizador_atual)],
    db: Annotated[Session, Depends(get_db)],
):
    """Administrador: ata em qualquer estado. Residente: só ata aprovada, senão 404."""
    try:
        ata = _reuniao_do_condominio(db, _condominio_de(quem), reuniao_id).ata
    except OperationalError as exc:
        raise _indisponivel() from exc
    if isinstance(quem, models.Administrador):
        if ata is None:
            raise _sem_ata()
        return schemas.AtaAdminOut.model_validate(ata)
    # Ao residente, uma ata por aprovar é igual a não haver ata: não revela o rascunho.
    if ata is None or ata.estado != models.EstadoAta.aprovada:
        raise _sem_ata()
    return schemas.AtaPublicaOut.model_validate(ata)


@router.put("/{reuniao_id}/ata", response_model=schemas.AtaAdminOut)
def guardar_rascunho(
    reuniao_id: int,
    dados: schemas.AtaRascunhoIn,
    admin: Annotated[models.Administrador, Depends(admin_do_pedido)],
    db: Annotated[Session, Depends(get_db)],
):
    """Guarda o rascunho editado. Não publica. Ata continua `pendente_revisao`."""
    try:
        ata = _ata_do_admin(db, admin, reuniao_id)
        alteradas = (
            db.query(models.Ata)
            .filter(models.Ata.id == ata.id, models.Ata.estado == PENDENTE)
            .update({"rascunho": dados.rascunho}, synchronize_session=False)
        )
        if alteradas == 0:
            db.rollback()
            db.refresh(ata)
            raise _conflito(ata.estado)
        db.commit()
        db.refresh(ata)
    except OperationalError as exc:
        db.rollback()
        raise _indisponivel() from exc
    return ata


@router.post("/{reuniao_id}/ata/aprovar", response_model=schemas.AtaAdminOut)
def aprovar_ata(
    reuniao_id: int,
    admin: Annotated[models.Administrador, Depends(admin_do_pedido)],
    db: Annotated[Session, Depends(get_db)],
):
    """Publica o rascunho guardado e regista quem aprovou.

    No mesmo UPDATE: `texto_aprovado` recebe o rascunho e são limpos o rascunho,
    a transcrição e `audio_path`. O ficheiro de áudio só é apagado depois do
    commit; se o commit falhar, o áudio continua guardado.
    """
    try:
        ata = _ata_do_admin(db, admin, reuniao_id)
        audio_path = ata.audio_path
        alteradas = (
            db.query(models.Ata)
            .filter(
                models.Ata.id == ata.id,
                models.Ata.estado == PENDENTE,
                models.Ata.rascunho.is_not(None),
                func.trim(models.Ata.rascunho) != "",
            )
            .update(
                {
                    # O lado direito usa o valor antes do UPDATE (PostgreSQL e SQLite).
                    "texto_aprovado": models.Ata.rascunho,
                    "rascunho": None,
                    "transcricao": None,
                    "audio_path": None,
                    "estado": models.EstadoAta.aprovada,
                    "aprovada_em": datetime.now(timezone.utc),
                    "aprovada_por": admin.id,
                },
                synchronize_session=False,
            )
        )
        if alteradas == 0:
            db.rollback()
            db.refresh(ata)
            # Pendente mas sem rascunho (ou só espaços) também dá `ata_sem_rascunho`.
            raise _conflito(ata.estado)
        db.commit()
        db.refresh(ata)
    except OperationalError as exc:
        db.rollback()
        raise _indisponivel() from exc
    apagar_audio(audio_path)
    return ata
