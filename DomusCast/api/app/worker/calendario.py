"""Worker do job `publicar_calendario` (US-28): publica a reunião no serviço de
calendário externo e atualiza `reuniao.estado_sync`.

- Sucesso: `sincronizada`, com `calendario_externo_id`.
- Falha (indisponível, atrasado, incompleto, inválido, 400 ou 429): nova tentativa com
  backoff; com `429`, espera pelo menos o `Retry-After`. Cada falha conta como tentativa.
- Ao fim de 5 tentativas falhadas: job `falhou` e reunião `alternativo` (fica no feed
  iCal, US-29).

Corre num processo próprio, para uma transcrição longa (US-10) não atrasar a publicação:
`python -m app.worker.calendario` (serviço `worker-calendario` no docker-compose.yml).
`GET /health` na porta `WORKER_HEALTH_PORT` (8082) verifica a base de dados e
`GET /metrics`, na mesma porta, dá as métricas Prometheus (8.7, T-07).
"""

import json
import logging
import os
import time
from datetime import datetime, timedelta, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from threading import Thread

from prometheus_client import CONTENT_TYPE_LATEST, Counter, Gauge, Histogram, generate_latest
from sqlalchemy import or_, select, text, update
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from .. import models
from ..database import SessionLocal
from ..routers.reunioes import JOB_PUBLICAR
from .calendario_provider import CalendarProvider, FalhaCalendario, ServicoCalendarioProvider

MAX_TENTATIVAS = 5
# Espera depois da 1.ª, 2.ª, 3.ª e 4.ª falha (8.5); a 5.ª falha termina o job.
ESPERAS = (1, 2, 4, 8)
INTERVALO_S = 2.0

log = logging.getLogger("domuscast.worker.calendario")

# Métricas de 8.5 e 8.7. `jobs_pendentes` lê-se da base de dados em cada leitura de
# /metrics; os contadores são do processo e recomeçam a zero quando o Worker reinicia.
JOBS_PENDENTES = Gauge("jobs_pendentes", "Jobs à espera de serem processados.", ["tipo"])
JOBS_FALHADOS = Counter(
    "jobs_falhados", "Jobs que esgotaram as tentativas.", ["tipo"]
)
JOB_DURACAO = Histogram(
    "job_duracao_segundos", "Duração de cada tentativa de um job.", ["tipo"],
    buckets=(0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0, 30.0),
)
FALHAS_INTEGRACAO = Counter(
    "integracao_falhas",
    "Falhas ao chamar um serviço externo, por provider e motivo (8.6).",
    ["provider", "motivo"],
)


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
    """Jobs de publicação `em_curso` de um Worker que caiu voltam a `pendente`.

    Só os deste tipo: os de transcrição (US-10) são de outro processo e podem estar a
    correr nesse momento.
    """
    resultado = db.execute(
        update(models.Job)
        .where(
            models.Job.tipo == JOB_PUBLICAR,
            models.Job.estado == models.EstadoJob.em_curso,
        )
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
    inicio = time.perf_counter()
    try:
        evento_id = provider.publicar(reuniao)
    except FalhaCalendario as falha:
        JOB_DURACAO.labels(JOB_PUBLICAR).observe(time.perf_counter() - inicio)
        # Só a categoria ("indisponivel: 503" -> "indisponivel"), para as etiquetas não
        # crescerem sem limite.
        FALHAS_INTEGRACAO.labels("calendario", falha.motivo.split(":", 1)[0]).inc()
        job.erro = falha.motivo
        if job.tentativas >= MAX_TENTATIVAS:
            JOBS_FALHADOS.labels(JOB_PUBLICAR).inc()
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
        JOB_DURACAO.labels(JOB_PUBLICAR).observe(time.perf_counter() - inicio)
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


def estado_saude(db: Session) -> dict:
    """Corpo de `GET /health`: a base de dados responde e quantos jobs esperam."""
    db.execute(text("SELECT 1"))
    pendentes = (
        db.query(models.Job)
        .filter_by(tipo=JOB_PUBLICAR, estado=models.EstadoJob.pendente)
        .count()
    )
    JOBS_PENDENTES.labels(JOB_PUBLICAR).set(pendentes)
    return {"status": "ok", "db": "ok", "jobs_pendentes": pendentes}


def metricas(db: Session) -> bytes:
    """Corpo de `GET /metrics`: atualiza `jobs_pendentes` e devolve o texto Prometheus."""
    estado_saude(db)
    return generate_latest()


class _Saude(BaseHTTPRequestHandler):  # pragma: no cover (servidor do container)
    def do_GET(self):  # noqa: N802 (nome do método do http.server)
        if self.path not in ("/health", "/metrics"):
            self.send_error(404)
            return
        tipo = "application/json"
        try:
            with SessionLocal() as db:
                if self.path == "/metrics":
                    dados, codigo, tipo = metricas(db), 200, CONTENT_TYPE_LATEST
                else:
                    dados, codigo = json.dumps(estado_saude(db)).encode(), 200
        except SQLAlchemyError:
            dados = json.dumps({"status": "erro", "db": "indisponivel"}).encode()
            codigo = 503
        self.send_response(codigo)
        self.send_header("Content-Type", tipo)
        self.send_header("Content-Length", str(len(dados)))
        self.end_headers()
        self.wfile.write(dados)

    def log_message(self, formato, *args):
        # O healthcheck corre de 10 em 10 s e o Prometheus lê /metrics; não enchem o log.
        return


def main() -> None:  # pragma: no cover (ciclo do container)
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    logging.getLogger("httpx").setLevel(logging.WARNING)
    porta = int(os.getenv("WORKER_HEALTH_PORT", "8082"))
    # Só o healthcheck do Docker e o Prometheus (rede interna) lhe chegam: não publica portas.
    servidor = ThreadingHTTPServer(("0.0.0.0", porta), _Saude)  # noqa: S104
    Thread(target=servidor.serve_forever, daemon=True).start()
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
