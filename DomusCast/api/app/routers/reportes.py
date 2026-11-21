"""US-02/US-09: reportes de avarias com as regras de visibilidade do autor (10.2).

O administrador vê sempre o nome e a fração do autor. Os residentes nunca recebem
a fração e só recebem o nome quando o autor escolheu mostrá-lo nesse reporte.
"""

import io
import os
import warnings
from pathlib import Path
from typing import Annotated
from uuid import uuid4

from fastapi import APIRouter, Depends, Header, HTTPException, Request, Response
from fastapi.concurrency import run_in_threadpool
from fastapi.exceptions import RequestValidationError
from pydantic import ValidationError
from sqlalchemy.exc import IntegrityError, OperationalError
from sqlalchemy.orm import Session
from starlette.datastructures import UploadFile
from starlette.formparsers import MultiPartException
from PIL import Image, ImageOps, UnidentifiedImageError

from .. import models, schemas
from ..database import get_db
from ..security import residente_atual, utilizador_atual

router = APIRouter()

MAX_FOTO_BYTES = 5 * 1024 * 1024
MEDIA_ROOT = Path(os.getenv("MEDIA_ROOT", "media"))
FORM_FIELDS = {"descricao", "foto_alt", "mostrar_nome", "foto"}


def _erro_validacao(mensagem: str) -> HTTPException:
    return HTTPException(status_code=422, detail=mensagem)


def _indisponivel() -> HTTPException:
    return HTTPException(
        status_code=503,
        detail="A base de dados está temporariamente indisponível.",
        headers={"Retry-After": "5"},
    )


def _vista(
    reporte: models.Reporte, quem: models.Administrador | models.Identidade
) -> schemas.ReporteOut:
    # Uma identidade removida (US-23) deixa de ser mostrada como autora.
    autor = reporte.autor if reporte.autor is not None and reporte.autor.removida_em is None else None
    autor_removido = False
    if isinstance(quem, models.Administrador):
        autor_nome = autor.nome if autor else None
        # A fração mantém-se para o administrador mesmo depois da remoção (ecrã 4 da US-23).
        fracao = reporte.autor.fracao.designacao if reporte.autor is not None else None
        autor_removido = reporte.autor is not None and autor is None
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
        autor_removido=autor_removido,
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


def _procurar(db: Session, residente: models.Identidade, chave: str) -> models.Reporte | None:
    try:
        return _por_chave(db, residente, chave)
    except OperationalError as exc:
        raise _indisponivel() from exc


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


async def _ler_foto(foto: UploadFile | None) -> bytes | None:
    if foto is None:
        return None
    try:
        conteudo = await foto.read(MAX_FOTO_BYTES + 1)
    finally:
        await foto.close()
    if len(conteudo) > MAX_FOTO_BYTES:
        raise _erro_validacao("A foto não pode exceder 5 MB.")
    return conteudo


def _guardar_foto(conteudo: bytes) -> tuple[str, Path]:
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


def _apagar(caminho: Path | None) -> None:
    if caminho is not None:
        caminho.unlink(missing_ok=True)


def _criar(
    db: Session,
    residente: models.Identidade,
    payload: schemas.ReporteCreate,
    foto: bytes | None,
    chave: str,
) -> tuple[models.Reporte, bool]:
    """Grava o reporte e devolve `(reporte, criado)`.

    Corre fora do event loop, porque o Pillow e o SQLAlchemy são síncronos.
    """
    foto_path, caminho_foto = _guardar_foto(foto) if foto is not None else (None, None)
    reporte = models.Reporte(
        condominio_id=residente.fracao.condominio_id,
        autor_id=residente.id,
        descricao=payload.descricao,
        foto_path=foto_path,
        foto_alt=payload.foto_alt,
        mostrar_nome=payload.mostrar_nome,
        estado=models.EstadoReporte.aberto,
        idempotency_key=chave,
    )
    db.add(reporte)
    try:
        db.commit()
    except IntegrityError:
        # Dois pedidos simultâneos do mesmo autor com a mesma chave: devolve o que ficou gravado.
        db.rollback()
        _apagar(caminho_foto)
        existente = _procurar(db, residente, chave)
        if existente is None:
            raise
        return existente, False
    except OperationalError as exc:
        db.rollback()
        _apagar(caminho_foto)
        raise _indisponivel() from exc
    db.refresh(reporte)
    return reporte, True


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
    idempotency_key: Annotated[
        str, Header(alias="Idempotency-Key", min_length=1, max_length=64)
    ],
    residente: Annotated[models.Identidade, Depends(residente_atual)],
    db: Annotated[Session, Depends(get_db)],
):
    """US-02/US-09: o residente cria um reporte e escolhe se mostra o nome (falso por omissão).

    201 com o reporte novo; 200 com o mesmo reporte num reenvio com a mesma chave.
    """
    reporte = await run_in_threadpool(_procurar, db, residente, idempotency_key)
    criado = False
    if reporte is None:
        payload, foto = await _ler_formulario(request)
        conteudo = await _ler_foto(foto)
        reporte, criado = await run_in_threadpool(
            _criar, db, residente, payload, conteudo, idempotency_key
        )
    if not criado:
        response.status_code = 200
    return await run_in_threadpool(_vista, reporte, residente)


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
