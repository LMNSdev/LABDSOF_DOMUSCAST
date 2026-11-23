"""US-10: áudio e rascunho de ata, privados aos administradores."""

import hashlib
import json
import os
from pathlib import Path
from typing import Annotated
from uuid import uuid4

from fastapi import APIRouter, Depends, File, HTTPException, Request, UploadFile
from sqlalchemy.exc import OperationalError
from sqlalchemy.orm import Session

from .. import models, schemas
from ..database import get_db
from ..erros import ErroApi
from ..security import admin_do_pedido

router = APIRouter()
MEDIA_ROOT = Path(os.getenv("MEDIA_ROOT", "media"))
MAX_AUDIO_BYTES = 200 * 1024 * 1024
EXTENSOES = {".mp3", ".m4a", ".wav"}
BLOCO = 1024 * 1024
JOB_TRANSCRICAO = "transcrever"


def _indisponivel() -> HTTPException:
    return HTTPException(
        status_code=503,
        detail="A base de dados está temporariamente indisponível.",
        headers={"Retry-After": "5"},
    )


def _validar_formato(nome: str, cabecalho: bytes) -> str:
    extensao = Path(nome).suffix.lower()
    if extensao not in EXTENSOES:
        raise ErroApi(415, "formato_audio_nao_suportado", "Use MP3, M4A ou WAV.")
    valido = {
        ".mp3": cabecalho.startswith(b"ID3") or (len(cabecalho) > 1 and cabecalho[0] == 0xFF and cabecalho[1] & 0xE0 == 0xE0),
        ".m4a": cabecalho[4:8] == b"ftyp",
        ".wav": cabecalho.startswith(b"RIFF") and cabecalho[8:12] == b"WAVE",
    }[extensao]
    if not valido:
        raise ErroApi(415, "formato_audio_nao_suportado", "O conteúdo não corresponde ao formato do ficheiro.")
    return extensao


def _guardar_audio(audio: UploadFile) -> tuple[str, Path, str]:
    """Copia o ficheiro em blocos, com limite, nome aleatório e hash para reenvios."""
    caminho_relativo = Path("atas") / f"{uuid4().hex}{Path(audio.filename or '').suffix.lower()}"
    caminho = MEDIA_ROOT / caminho_relativo
    caminho.parent.mkdir(parents=True, exist_ok=True)
    temporario = caminho.with_suffix(caminho.suffix + ".part")
    tamanho = 0
    digest = hashlib.sha256()
    cabecalho = b""
    try:
        with temporario.open("xb") as destino:
            while bloco := audio.file.read(BLOCO):
                tamanho += len(bloco)
                if tamanho > MAX_AUDIO_BYTES:
                    raise ErroApi(413, "audio_demasiado_grande", "O áudio não pode exceder 200 MB.")
                if len(cabecalho) < 12:
                    cabecalho = (cabecalho + bloco)[:12]
                digest.update(bloco)
                destino.write(bloco)
        if tamanho == 0:
            raise ErroApi(422, "audio_vazio", "Selecione um ficheiro de áudio não vazio.")
        _validar_formato(audio.filename or "", cabecalho)
        temporario.replace(caminho)
        return caminho_relativo.as_posix(), caminho, digest.hexdigest()
    finally:
        temporario.unlink(missing_ok=True)
        audio.file.close()


def _resposta(ata: models.Ata) -> dict:
    return {
        "id": ata.id,
        "reuniao_id": ata.reuniao_id,
        "estado": ata.estado,
        "origem": ata.origem,
        "audio_guardado": ata.audio_path is not None,
        "transcricao": ata.transcricao,
        "rascunho": ata.rascunho,
        "texto_aprovado": ata.texto_aprovado,
    }


@router.post("/{reuniao_id}/ata/audio", response_model=schemas.AtaOut, status_code=202)
def carregar_audio(
    reuniao_id: int,
    request: Request,
    audio: Annotated[UploadFile, File()],
    admin: Annotated[models.Administrador, Depends(admin_do_pedido)],
    db: Annotated[Session, Depends(get_db)],
):
    try:
        reuniao = db.query(models.Reuniao).filter(
            models.Reuniao.id == reuniao_id,
            models.Reuniao.condominio_id == admin.condominio_id,
        ).first()
        if reuniao is None:
            raise HTTPException(status_code=404, detail="Reunião não encontrada.")
        ata_existente = db.query(models.Ata).filter_by(reuniao_id=reuniao_id).first()
        if ata_existente is not None and ata_existente.estado == models.EstadoAta.aprovada:
            raise ErroApi(409, "ata_ja_aprovada", "A ata já foi aprovada.")
        db.rollback()  # não manter a transação aberta durante a leitura do upload
    except OperationalError as exc:
        db.rollback()
        raise _indisponivel() from exc

    caminho_relativo, caminho, digest = _guardar_audio(audio)
    manter_ficheiro = False
    try:
        # O lock da reunião serializa dois uploads simultâneos no PostgreSQL.
        reuniao = db.query(models.Reuniao).filter(
            models.Reuniao.id == reuniao_id,
            models.Reuniao.condominio_id == admin.condominio_id,
        ).with_for_update().first()
        if reuniao is None:
            raise HTTPException(status_code=404, detail="Reunião não encontrada.")
        ata = db.query(models.Ata).filter_by(reuniao_id=reuniao_id).first()
        if ata is not None:
            if ata.estado == models.EstadoAta.aprovada:
                raise ErroApi(409, "ata_ja_aprovada", "A ata já foi aprovada.")
            if ata.audio_sha256 != digest:
                raise ErroApi(409, "audio_diferente", "Esta reunião já tem outro áudio.")
            if ata.estado == models.EstadoAta.falhou_transcricao:
                job = db.query(models.Job).filter_by(chave_idempotencia=f"transcrever:{ata.id}").one()
                job.estado = models.EstadoJob.pendente
                job.tentativas = 0
                job.proxima_tentativa_em = None
                job.erro = None
                ata.estado = models.EstadoAta.a_transcrever
                ata.rascunho = None
                db.commit()
            return _resposta(ata)

        ata = models.Ata(
            reuniao_id=reuniao_id,
            audio_path=caminho_relativo,
            audio_sha256=digest,
            origem=models.OrigemAta.ia,
            estado=models.EstadoAta.a_transcrever,
        )
        db.add(ata)
        db.flush()
        db.add(models.Job(
            tipo=JOB_TRANSCRICAO,
            chave_idempotencia=f"transcrever:{ata.id}",
            payload=json.dumps({"ata_id": ata.id}),
            request_id=request.state.request_id,
        ))
        db.commit()
        manter_ficheiro = True
        return _resposta(ata)
    except OperationalError as exc:
        db.rollback()
        raise _indisponivel() from exc
    finally:
        if not manter_ficheiro:
            caminho.unlink(missing_ok=True)


@router.get("/{reuniao_id}/ata", response_model=schemas.AtaOut)
def consultar_ata(
    reuniao_id: int,
    admin: Annotated[models.Administrador, Depends(admin_do_pedido)],
    db: Annotated[Session, Depends(get_db)],
):
    try:
        ata = db.query(models.Ata).join(models.Reuniao).filter(
            models.Ata.reuniao_id == reuniao_id,
            models.Reuniao.condominio_id == admin.condominio_id,
        ).first()
    except OperationalError as exc:
        raise _indisponivel() from exc
    if ata is None:
        raise HTTPException(status_code=404, detail="Ata não encontrada.")
    return _resposta(ata)
