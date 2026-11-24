"""Worker: consome os jobs da tabela `job` (outbox, 8.5 e ADR-005).

Por agora trata o job `publicar_calendario` (US-28): publica a reunião no serviço de
calendário externo e atualiza `reuniao.estado_sync`.

- Sucesso: `sincronizada`, com `calendario_externo_id`.
- Falha (indisponível, atrasado, incompleto, inválido, 400 ou 429): nova tentativa com
  backoff; com `429`, espera pelo menos o `Retry-After`. Cada falha conta como tentativa.
- Ao fim de 5 tentativas falhadas: job `falhou` e reunião `alternativo` (fica no feed
  iCal, US-29).

Arranque: `python -m app.worker` (container `worker` no docker-compose.yml).
"""

import json
import logging
import os
import time
from datetime import datetime, timedelta, timezone

from sqlalchemy import or_, select, update
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from . import models
from .calendario import CalendarProvider, FalhaCalendario, ServicoCalendarioProvider
from .database import SessionLocal
from .routers.reunioes import JOB_PUBLICAR

MAX_TENTATIVAS = 5
# Espera depois da 1.ª, 2.ª, 3.ª e 4.ª falha (8.5); a 5.ª falha termina o job.
ESPERAS = (1, 2, 4, 8)
INTERVALO_S = 2.0

log = logging.getLogger("domuscast.worker")


def _registar(nivel: int, evento: str, **campos) -> None:
    log.log(
        nivel,
        json.dumps(
            {
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "componente": "calendario",
                "evento": evento,
                **campos,
            },
            ensure_ascii=False,
        ),
    )


def repor_jobs_interrompidos(db: Session) -> int:
    """Jobs `em_curso` de um Worker que caiu voltam a `pendente` (há um só Worker)."""
    resultado = db.execute(
        update(models.Job)
        .where(models.Job.estado == models.EstadoJob.em_curso)
        .values(estado=models.EstadoJob.pendente)
    )
    db.commit()
    return resultado.rowcount


def reservar_job(db: Session, agora: datetime) -> models.Job | None:
    consulta = (
        select(models.Job)
        .where(
            models.Job.tipo == JOB_PUBLICAR,
            models.Job.estado == models.EstadoJob.pendente,
            or_(
                models.Job.proxima_tentativa_em.is_(None),
                models.Job.proxima_tentativa_em <= agora,
            ),
        )
        .order_by(models.Job.id)
        .limit(1)
        .with_for_update(skip_locked=True)
    )
    job = db.scalars(consulta).first()
    if job is not None:
        job.estado = models.EstadoJob.em_curso
        db.commit()
    return job


def processar_job(
    db: Session,
    job: models.Job,
    provider: CalendarProvider,
    agora: datetime,
    unidade_backoff_s: float = 60.0,
) -> None:
    try:
        reuniao_id = int(json.loads(job.payload)["reuniao_id"])
    except (TypeError, ValueError, KeyError):
        # Um job mal formado falha sozinho e não para o Worker.
        job.estado = models.EstadoJob.falhou
        job.erro = "payload inválido"
        db.commit()
        _registar(logging.ERROR, "payload_invalido", job_id=job.id)
        return
    reuniao = db.get(models.Reuniao, reuniao_id)
    if reuniao is None:
        job.estado = models.EstadoJob.falhou
        job.erro = "reunião não existe"
        db.commit()
        return
    if reuniao.estado_sync == models.EstadoSyncReuniao.sincronizada:
        job.estado = models.EstadoJob.concluido
        db.commit()
        return

    job.tentativas += 1
    try:
        evento_id = provider.publicar(reuniao)
    except FalhaCalendario as falha:
        job.erro = falha.motivo
        if job.tentativas >= MAX_TENTATIVAS:
            job.estado = models.EstadoJob.falhou
            job.proxima_tentativa_em = None
            reuniao.estado_sync = models.EstadoSyncReuniao.alternativo
            _registar(
                logging.ERROR, "publicacao_falhou", reuniao_id=reuniao.id, job_id=job.id,
                tentativa=job.tentativas, motivo=falha.motivo, estado_sync="alternativo",
            )
        else:
            espera = ESPERAS[job.tentativas - 1] * unidade_backoff_s
            espera = max(espera, falha.retry_after_s or 0.0)
            job.estado = models.EstadoJob.pendente
            job.proxima_tentativa_em = agora + timedelta(seconds=espera)
            _registar(
                logging.WARNING, "tentativa_falhou", reuniao_id=reuniao.id, job_id=job.id,
                tentativa=job.tentativas, motivo=falha.motivo, proxima_em_s=espera,
            )
    else:
        reuniao.calendario_externo_id = evento_id
        reuniao.estado_sync = models.EstadoSyncReuniao.sincronizada
        job.estado = models.EstadoJob.concluido
        job.erro = None
        job.proxima_tentativa_em = None
        _registar(
            logging.INFO, "publicada", reuniao_id=reuniao.id, job_id=job.id,
            tentativa=job.tentativas, evento_id=evento_id,
        )
    db.commit()


def executar_um(
    db: Session, provider: CalendarProvider, unidade_backoff_s: float = 60.0
) -> bool:
    """Processa um job, se houver algum pronto. Devolve se processou."""
    agora = datetime.now(timezone.utc)
    job = reservar_job(db, agora)
    if job is None:
        return False
    processar_job(db, job, provider, agora, unidade_backoff_s)
    return True


def main() -> None:  # pragma: no cover (ciclo do container)
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    logging.getLogger("httpx").setLevel(logging.WARNING)
    provider = ServicoCalendarioProvider(os.environ["CALENDARIO_URL"])
    # Só para demonstrações: 1 faz as esperas de 1, 2, 4 e 8 segundos em vez de minutos.
    unidade = float(os.getenv("WORKER_BACKOFF_UNIDADE_S", "60"))
    reposto = False
    while True:
        try:
            with SessionLocal() as db:
                if not reposto:
                    repor_jobs_interrompidos(db)
                    reposto = True
                trabalhou = executar_um(db, provider, unidade)
        except SQLAlchemyError as exc:
            # Base de dados em baixo ou migrações ainda por correr: os jobs esperam.
            log.warning(json.dumps({"componente": "worker", "evento": "bd_indisponivel",
                                    "erro": type(exc).__name__}))
            trabalhou = False
        except Exception:
            # Um erro inesperado num job não pode parar a publicação dos outros.
            log.exception(json.dumps({"componente": "worker", "evento": "erro_inesperado"}))
            trabalhou = False
        if not trabalhou:
            time.sleep(INTERVALO_S)


if __name__ == "__main__":  # pragma: no cover
    main()
