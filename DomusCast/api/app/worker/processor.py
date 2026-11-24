"""Outbox PostgreSQL para transcrição de atas (US-10, ADR-005)."""

import json
import logging
import os
from datetime import datetime, timedelta, timezone
from pathlib import Path
from time import monotonic
from typing import Callable, Protocol

from sqlalchemy import or_
from sqlalchemy.orm import Session

from .. import models
from ..database import SessionLocal
from .openai_provider import FalhaProvider, OpenAIProvider


MAX_TENTATIVAS = 5
# Cinco tentativas totais dão quatro intervalos. O quinto valor (16 min) do
# refinamento só seria usado se a equipa aprovasse uma sexta tentativa.
ESPERAS_MINUTOS = (1, 2, 4, 8)
logger = logging.getLogger("domuscast.worker")


class Provider(Protocol):
    def transcrever(self, caminho: Path) -> str: ...
    def gerar_rascunho(self, transcricao: str) -> str: ...


SessionFactory = Callable[[], Session]


def limpar_audios_aprovados(
    sessoes: SessionFactory = SessionLocal, media_root: Path | None = None,
) -> int:
    """Conclui a limpeza após aprovação, incluindo depois de um crash.

    A US-24 deve guardar o estado `aprovada` e conservar `audio_path` até
    esta limpeza. Assim, uma interrupção entre o commit e o unlink é retomada.
    """
    raiz = (media_root or Path(os.getenv("MEDIA_ROOT", "media"))).resolve()
    removidos = 0
    while True:
        with sessoes() as db:
            ata = db.query(models.Ata).filter(
                models.Ata.estado == models.EstadoAta.aprovada,
                models.Ata.audio_path.isnot(None),
            ).order_by(models.Ata.id).with_for_update(skip_locked=True).first()
            if ata is None:
                return removidos
            caminho = (raiz / ata.audio_path).resolve()
            if caminho.is_relative_to(raiz):
                try:
                    caminho.unlink(missing_ok=True)
                except OSError:
                    # Um erro no volume não deve impedir outros jobs do Worker.
                    logger.warning(json.dumps({"componente": "worker", "evento": "audio_aprovado_pendente",
                                               "ata_id": ata.id}))
                    return removidos
            ata.audio_path = None
            ata.audio_sha256 = None
            ata.transcricao = None
            ata.rascunho = None
            db.commit()
            removidos += 1
            _log("audio_aprovado_eliminado", ata_id=ata.id)


def _log(evento: str, job: models.Job | None = None, **campos: object) -> None:
    logger.info(json.dumps({
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "componente": "worker",
        "evento": evento,
        "job_id": job.id if job else None,
        "request_id": job.request_id if job else None,
        **campos,
    }))


def recuperar_jobs(sessoes: SessionFactory = SessionLocal) -> int:
    """Um único Worker repõe jobs interrompidos por crash ao arrancar."""
    with sessoes() as db:
        jobs = db.query(models.Job).filter(
            models.Job.tipo == "transcrever",
            models.Job.estado == models.EstadoJob.em_curso,
        ).all()
        for job in jobs:
            job.estado = models.EstadoJob.pendente
            job.proxima_tentativa_em = None
        db.commit()
        return len(jobs)


def reservar_job(sessoes: SessionFactory = SessionLocal) -> int | None:
    with sessoes() as db:
        agora = datetime.now(timezone.utc)
        job = db.query(models.Job).filter(
            models.Job.tipo == "transcrever",
            models.Job.estado == models.EstadoJob.pendente,
            or_(models.Job.proxima_tentativa_em.is_(None), models.Job.proxima_tentativa_em <= agora),
        ).order_by(models.Job.id).with_for_update(skip_locked=True).first()
        if job is None:
            return None
        job.estado = models.EstadoJob.em_curso
        job.tentativas += 1
        db.commit()
        return job.id


def _ata_e_job(db: Session, job_id: int) -> tuple[models.Ata, models.Job]:
    job = db.get(models.Job, job_id)
    if job is None or job.tipo != "transcrever":
        raise FalhaProvider("job_invalido")
    try:
        ata_id = int(json.loads(job.payload or "{}")["ata_id"])
    except (ValueError, KeyError, TypeError) as exc:
        raise FalhaProvider("job_invalido") from exc
    ata = db.get(models.Ata, ata_id)
    if ata is None:
        raise FalhaProvider("ata_nao_encontrada")
    return ata, job


def _concluido_sem_alterar(ata: models.Ata) -> bool:
    return ata.estado != models.EstadoAta.a_transcrever or ata.origem != models.OrigemAta.ia


def _gravar_transcricao(job_id: int, texto: str, sessoes: SessionFactory) -> bool:
    with sessoes() as db:
        ata, job = _ata_e_job(db, job_id)
        db.query(models.Ata).filter_by(id=ata.id).with_for_update().first()
        if _concluido_sem_alterar(ata):
            job.estado = models.EstadoJob.concluido
            db.commit()
            return False
        ata.transcricao = texto
        db.commit()
        return True


def _gravar_rascunho(job_id: int, texto: str, sessoes: SessionFactory) -> None:
    with sessoes() as db:
        ata, job = _ata_e_job(db, job_id)
        db.query(models.Ata).filter_by(id=ata.id).with_for_update().first()
        if not _concluido_sem_alterar(ata):
            ata.rascunho = texto
            ata.estado = models.EstadoAta.pendente_revisao
        job.estado = models.EstadoJob.concluido
        job.erro = None
        db.commit()
        _log("transcricao_concluida", job)


def _registar_falha(job_id: int, codigo: str, sessoes: SessionFactory) -> None:
    with sessoes() as db:
        ata, job = _ata_e_job(db, job_id)
        if _concluido_sem_alterar(ata):
            job.estado = models.EstadoJob.concluido
        elif job.tentativas >= MAX_TENTATIVAS:
            job.estado = models.EstadoJob.falhou
            ata.estado = models.EstadoAta.falhou_transcricao
        else:
            job.estado = models.EstadoJob.pendente
            espera = ESPERAS_MINUTOS[job.tentativas - 1]
            job.proxima_tentativa_em = datetime.now(timezone.utc) + timedelta(minutes=espera)
        job.erro = codigo  # nunca guardar a resposta da IA, áudio ou transcrição
        db.commit()
        _log("transcricao_falhou", job, codigo=codigo, tentativas=job.tentativas)


def processar_job(
    job_id: int,
    provider: Provider | None = None,
    sessoes: SessionFactory = SessionLocal,
    media_root: Path | None = None,
) -> None:
    provider = provider or OpenAIProvider()
    raiz = (media_root or Path(os.getenv("MEDIA_ROOT", "media"))).resolve()
    inicio = monotonic()
    try:
        with sessoes() as db:
            ata, job = _ata_e_job(db, job_id)
            if _concluido_sem_alterar(ata):
                job.estado = models.EstadoJob.concluido
                db.commit()
                return
            if not ata.audio_path:
                raise FalhaProvider("audio_em_falta")
            caminho = (raiz / ata.audio_path).resolve()
            if not caminho.is_relative_to(raiz) or not caminho.is_file():
                raise FalhaProvider("audio_em_falta")
            transcricao = ata.transcricao

        if not transcricao:
            transcricao = provider.transcrever(caminho)
            if not transcricao.strip():
                raise FalhaProvider("transcricao_vazia")
            if not _gravar_transcricao(job_id, transcricao, sessoes):
                return
        rascunho = provider.gerar_rascunho(transcricao)
        if not rascunho.strip():
            raise FalhaProvider("rascunho_vazio")
        _gravar_rascunho(job_id, rascunho, sessoes)
    except FalhaProvider as exc:
        _registar_falha(job_id, str(exc), sessoes)
    except Exception:
        logger.exception("falha_interna_no_job_sem_conteudo_pessoal")
        _registar_falha(job_id, "falha_interna", sessoes)
    finally:
        logger.info(json.dumps({"evento": "job_duracao", "job_id": job_id,
                                "duracao_segundos": round(monotonic() - inicio, 3)}))
