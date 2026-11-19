import io
import os
import warnings
from pathlib import Path
from typing import Annotated
from uuid import uuid4

from fastapi import APIRouter, Depends, Header, HTTPException, Request, Response
from fastapi.exceptions import RequestValidationError
from pydantic import ValidationError
from sqlalchemy.exc import IntegrityError, OperationalError
from sqlalchemy.orm import Session
from starlette.datastructures import UploadFile
from starlette.formparsers import MultiPartException
from PIL import Image, ImageOps, UnidentifiedImageError

from .. import models, schemas
from ..database import get_db
from ..security import identidade_atual, utilizador_atual

router = APIRouter()

MAX_FOTO_BYTES = 5 * 1024 * 1024
MEDIA_ROOT = Path(os.getenv("MEDIA_ROOT", "media"))
FORM_FIELDS = {"descricao", "foto_alt", "mostrar_nome", "foto"}


def _erro_validacao(mensagem: str) -> HTTPException:
    return HTTPException(status_code=422, detail=mensagem)


def _vista(
    reporte: models.Reporte,
    quem: models.Administrador | models.Identidade,
) -> dict:
    administrador = isinstance(quem, models.Administrador)
    return {
        "id": reporte.id,
        "descricao": reporte.descricao,
        "foto_url": reporte.foto_url,
        "estado": reporte.estado,
        "criado_em": reporte.criado_em,
        "atualizado_em": reporte.atualizado_em,
        "mostrar_nome": reporte.mostrar_nome,
        "autor_nome": (
            reporte.autor.nome
            if reporte.autor is not None
            and (administrador or reporte.mostrar_nome)
            else None
        ),
        "fracao": (
            reporte.autor.fracao.designacao
            if administrador and reporte.autor is not None
            else None
        ),
        "meu": (
            isinstance(quem, models.Identidade) and reporte.autor_id == quem.id
        ),
    }


async def _ler_formulario(
    request: Request,
) -> tuple[schemas.ReporteCreate, UploadFile | None]:
    content_type = (
        request.headers.get("content-type", "").split(";", maxsplit=1)[0].strip()
    )
    if content_type.lower() != "multipart/form-data":
        raise _erro_validacao("O pedido tem de usar multipart/form-data.")
    try:
        form = await request.form()
    except MultiPartException as exc:
        raise _erro_validacao("O formulário multipart é inválido.") from exc

    campos_extra = set(form.keys()) - FORM_FIELDS
    if campos_extra:
        raise _erro_validacao("O formulário contém campos não permitidos.")
    if any(len(form.getlist(campo)) != 1 for campo in form.keys()):
        raise _erro_validacao("Cada campo só pode ser enviado uma vez.")

    foto = form.get("foto")
    if foto is not None and not isinstance(foto, UploadFile):
        raise _erro_validacao("O campo foto tem de ser um ficheiro.")

    dados = {
        campo: form.get(campo)
        for campo in ("descricao", "foto_alt", "mostrar_nome")
        if campo in form
    }
    try:
        payload = schemas.ReporteCreate.model_validate(dados)
    except ValidationError as exc:
        raise RequestValidationError(exc.errors()) from exc

    if foto is not None and not payload.foto_alt:
        raise _erro_validacao("A descrição alternativa é obrigatória com uma foto.")

    return payload, foto


def _normalizar_foto(conteudo: bytes) -> tuple[bytes, str]:
    try:
        with warnings.catch_warnings():
            warnings.simplefilter("error", Image.DecompressionBombWarning)
            with Image.open(io.BytesIO(conteudo)) as imagem:
                formato = imagem.format
                if formato not in {"JPEG", "PNG"}:
                    raise _erro_validacao("A foto tem de estar no formato JPEG ou PNG.")
                imagem.verify()

            with Image.open(io.BytesIO(conteudo)) as imagem:
                imagem = ImageOps.exif_transpose(imagem)
                saida = io.BytesIO()
                if formato == "JPEG":
                    if imagem.mode not in {"RGB", "L"}:
                        imagem = imagem.convert("RGB")
                    imagem.save(saida, format="JPEG", quality=95, optimize=True)
                    extensao = "jpg"
                else:
                    imagem.save(saida, format="PNG", optimize=True)
                    extensao = "png"
                return saida.getvalue(), extensao
    except (
        UnidentifiedImageError,
        OSError,
        ValueError,
        Image.DecompressionBombError,
        Image.DecompressionBombWarning,
    ) as exc:
        raise _erro_validacao("A foto não é uma imagem válida.") from exc


async def _guardar_foto(foto: UploadFile | None) -> tuple[str | None, Path | None]:
    if foto is None:
        return None, None

    try:
        conteudo = await foto.read(MAX_FOTO_BYTES + 1)
    finally:
        await foto.close()

    if len(conteudo) > MAX_FOTO_BYTES:
        raise _erro_validacao("A foto não pode exceder 5 MB.")
    conteudo_normalizado, extensao = _normalizar_foto(conteudo)

    nome = f"{uuid4().hex}.{extensao}"
    caminho_relativo = Path("reportes") / nome
    caminho = MEDIA_ROOT / caminho_relativo
    caminho.parent.mkdir(parents=True, exist_ok=True)
    temporario = caminho.with_suffix(f".{uuid4().hex}.tmp")
    try:
        temporario.write_bytes(conteudo_normalizado)
        temporario.replace(caminho)
    finally:
        temporario.unlink(missing_ok=True)
    return caminho_relativo.as_posix(), caminho


@router.post(
    "",
    response_model=schemas.ReporteOut,
    status_code=201,
    openapi_extra={
        "requestBody": {
            "required": True,
            "content": {
                "multipart/form-data": {
                    "schema": {
                        "type": "object",
                        "additionalProperties": False,
                        "required": ["descricao"],
                        "properties": {
                            "descricao": {
                                "type": "string",
                                "minLength": 1,
                                "maxLength": 2000,
                            },
                            "foto": {"type": "string", "format": "binary"},
                            "foto_alt": {"type": "string", "maxLength": 300},
                            "mostrar_nome": {"type": "boolean", "default": False},
                        },
                    }
                }
            },
        }
    },
)
async def criar_reporte(
    request: Request,
    response: Response,
    idempotency_key: str = Header(
        ..., alias="Idempotency-Key", min_length=1, max_length=64
    ),
    identidade: models.Identidade = Depends(identidade_atual),
    db: Session = Depends(get_db),
):
    try:
        existente = (
            db.query(models.Reporte)
            .filter(
                models.Reporte.autor_id == identidade.id,
                models.Reporte.idempotency_key == idempotency_key,
            )
            .first()
        )
    except OperationalError as exc:
        raise HTTPException(
            status_code=503,
            detail="A base de dados está temporariamente indisponível.",
            headers={"Retry-After": "5"},
        ) from exc

    if existente is not None:
        response.status_code = 200
        return existente

    payload, foto = await _ler_formulario(request)
    foto_path, caminho_foto = await _guardar_foto(foto)

    reporte = models.Reporte(
        condominio_id=identidade.fracao.condominio_id,
        autor_id=identidade.id,
        descricao=payload.descricao,
        foto_path=foto_path,
        foto_alt=payload.foto_alt,
        mostrar_nome=payload.mostrar_nome,
        estado=models.EstadoReporte.aberto,
        idempotency_key=idempotency_key,
    )
    db.add(reporte)
    transacao_confirmada = False
    try:
        db.commit()
        transacao_confirmada = True
        db.refresh(reporte)
    except IntegrityError:
        db.rollback()
        existente = (
            db.query(models.Reporte)
            .filter(
                models.Reporte.autor_id == identidade.id,
                models.Reporte.idempotency_key == idempotency_key,
            )
            .first()
        )
        if existente is None:
            if caminho_foto is not None:
                caminho_foto.unlink(missing_ok=True)
            raise
        if caminho_foto is not None:
            caminho_foto.unlink(missing_ok=True)
        response.status_code = 200
        return existente
    except OperationalError as exc:
        db.rollback()
        if caminho_foto is not None and not transacao_confirmada:
            caminho_foto.unlink(missing_ok=True)
        raise HTTPException(
            status_code=503,
            detail="A base de dados está temporariamente indisponível.",
            headers={"Retry-After": "5"},
        ) from exc

    return reporte


@router.get("", response_model=list[schemas.ReporteOut])
def listar_reportes(
    quem: Annotated[
        models.Administrador | models.Identidade, Depends(utilizador_atual)
    ],
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
