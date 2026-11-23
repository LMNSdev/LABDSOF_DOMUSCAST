"""Entrypoint independente do Worker e endpoints de operação internos."""

import json
import logging
import os
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from threading import Thread
from time import sleep

from sqlalchemy import func, text
from sqlalchemy.exc import SQLAlchemyError

from .. import models
from ..database import SessionLocal
from .processor import limpar_audios_aprovados, processar_job, recuperar_jobs, reservar_job


logger = logging.getLogger("domuscast.worker")


class EstadoHandler(BaseHTTPRequestHandler):
    def do_GET(self):  # noqa: N802
        if self.path not in {"/health", "/metrics"}:
            self.send_error(404)
            return
        try:
            with SessionLocal() as db:
                db.execute(text("SELECT 1"))
                pendentes = db.query(models.Job).filter_by(
                    tipo="transcrever", estado=models.EstadoJob.pendente,
                ).count()
                falhados = db.query(models.Job).filter_by(
                    tipo="transcrever", estado=models.EstadoJob.falhou,
                ).count()
                mais_antigo = db.query(func.min(models.Job.criado_em)).filter(
                    models.Job.tipo == "transcrever",
                    models.Job.estado == models.EstadoJob.pendente,
                ).scalar()
            idade = 0 if mais_antigo is None else max(0, int((datetime.now(timezone.utc) -
                (mais_antigo if mais_antigo.tzinfo else mais_antigo.replace(tzinfo=timezone.utc))).total_seconds()))
            if self.path == "/health":
                corpo = json.dumps({"status": "ok", "db": "ok", "job_pendente_mais_antigo_s": idade})
                tipo = "application/json"
            else:
                corpo = (f"jobs_pendentes{{tipo=\"transcrever\"}} {pendentes}\n"
                         f"jobs_falhados{{tipo=\"transcrever\"}} {falhados}\n"
                         f"job_pendente_mais_antigo_segundos{{tipo=\"transcrever\"}} {idade}\n")
                tipo = "text/plain; version=0.0.4"
            self.send_response(200)
        except SQLAlchemyError:
            corpo = '{"status":"erro","db":"indisponivel"}'
            tipo = "application/json"
            self.send_response(503)
        dados = corpo.encode()
        self.send_header("Content-Type", tipo)
        self.send_header("Content-Length", str(len(dados)))
        self.end_headers()
        self.wfile.write(dados)

    def log_message(self, formato, *args):
        logger.info(json.dumps({"componente": "worker", "evento": "http",
                                "mensagem": formato % args}))


def main() -> None:
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    servidor = ThreadingHTTPServer(("0.0.0.0", int(os.getenv("WORKER_HEALTH_PORT", "8081"))), EstadoHandler)  # noqa: S104
    Thread(target=servidor.serve_forever, daemon=True).start()
    while True:
        try:
            recuperados = recuperar_jobs()
            logger.info(json.dumps({"componente": "worker", "evento": "arranque",
                                    "jobs_recuperados": recuperados}))
            break
        except SQLAlchemyError:
            logger.warning(json.dumps({"componente": "worker", "evento": "bd_indisponivel"}))
            sleep(5)
    while True:
        try:
            limpar_audios_aprovados()
            job_id = reservar_job()
            if job_id is None:
                sleep(2)
            else:
                processar_job(job_id)
        except SQLAlchemyError:
            logger.warning(json.dumps({"componente": "worker", "evento": "bd_indisponivel"}))
            sleep(5)


if __name__ == "__main__":
    main()
