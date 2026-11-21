"""US-15: o residente entra com o token do QR code da fração e o seu nome.
US-23: o administrador remove a identidade de quem saiu.

O token só é validado aqui, por isso a fração só é revelada depois de criada a
identidade. A credencial devolvida fica no telemóvel; o servidor guarda o hash.
"""

import unicodedata
from datetime import datetime, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Request, Response
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from .. import models, rate_limit, schemas
from ..database import get_db
from ..erros import ErroApi
from ..security import admin_do_pedido, gerar_token, hash_token

router = APIRouter()

MAX_IDENTIDADES_POR_FRACAO = 10
JANELA_S = 3600
TENTATIVAS_POR_QR = 30
TOKENS_INVALIDOS_POR_IP = 20
MENSAGEM_NOME_DUPLICADO = "Já existe alguém com este nome na sua fração."


def normalizar_nome(nome: str) -> str:
    """Ignora maiúsculas, acentos e espaços: "João  Dias" e "joao dias" são o mesmo nome."""
    sem_acentos = "".join(
        c for c in unicodedata.normalize("NFD", nome) if unicodedata.category(c) != "Mn"
    )
    return "".join(sem_acentos.casefold().split())


@router.post("", response_model=schemas.IdentidadeCriada, status_code=201)
def criar_identidade(
    dados: schemas.IdentidadeCreate,
    request: Request,
    db: Annotated[Session, Depends(get_db)],
):
    qr = (
        db.query(models.QrToken)
        .filter(
            models.QrToken.token_hash == hash_token(dados.token),
            models.QrToken.revogado_em.is_(None),
        )
        .first()
    )
    if qr is None:
        # Inválido e revogado têm a mesma resposta (TM-01). Só estas tentativas contam por IP.
        rate_limit.verificar(request, "identidade_token_invalido", TOKENS_INVALIDOS_POR_IP, JANELA_S)
        raise ErroApi(404, "qr_invalido", "Este QR code não é válido ou foi revogado.")

    # Por QR code e não por IP: os vizinhos partilham o IP público do prédio.
    rate_limit.verificar(
        request, f"identidade_qr:{qr.id}", TENTATIVAS_POR_QR, JANELA_S, por_ip=False
    )

    ativas = db.query(models.Identidade).filter(
        models.Identidade.fracao_id == qr.fracao_id,
        models.Identidade.removida_em.is_(None),
    )
    if ativas.count() >= MAX_IDENTIDADES_POR_FRACAO:
        raise ErroApi(409, "fracao_cheia", "Esta fração já tem 10 residentes.")

    nome_normalizado = normalizar_nome(dados.nome)
    if ativas.filter(models.Identidade.nome_normalizado == nome_normalizado).first():
        raise ErroApi(409, "nome_duplicado", MENSAGEM_NOME_DUPLICADO)

    credencial = gerar_token()
    identidade = models.Identidade(
        fracao_id=qr.fracao_id,
        qr_token_id=qr.id,
        nome=dados.nome,
        nome_normalizado=nome_normalizado,
        credencial_hash=hash_token(credencial),
    )
    db.add(identidade)
    try:
        db.commit()
    except IntegrityError:
        # Pedidos simultâneos com o mesmo nome, ou nome de uma identidade removida (#105).
        db.rollback()
        raise ErroApi(409, "nome_duplicado", MENSAGEM_NOME_DUPLICADO) from None

    return schemas.IdentidadeCriada(
        id=identidade.id,
        nome=identidade.nome,
        fracao=qr.fracao.designacao,
        credencial=credencial,
    )


@router.delete("/{identidade_id}", status_code=204)
def remover_identidade(
    identidade_id: int,
    admin: Annotated[models.Administrador, Depends(admin_do_pedido)],
    db: Annotated[Session, Depends(get_db)],
):
    """Apaga o nome e regista quem removeu; a credencial deixa de ser aceite (401).

    Os reportes ficam, sem autor visível ("Residente removido"). Como o nome
    normalizado fica vazio, o mesmo nome volta a ser aceite na fração.
    404 se não existir, já foi removida ou é de outro condomínio (não revela qual).

    Um só UPDATE condicional: numa remoção em simultâneo, a segunda recebe 404 e
    não sobrescreve quem removeu primeiro.
    """
    do_condominio = db.query(models.Fracao.id).filter(
        models.Fracao.condominio_id == admin.condominio_id
    )
    n = (
        db.query(models.Identidade)
        .filter(
            models.Identidade.id == identidade_id,
            models.Identidade.removida_em.is_(None),
            models.Identidade.fracao_id.in_(do_condominio),
        )
        .update(
            {
                "nome": None,
                "nome_normalizado": None,
                "removida_em": datetime.now(timezone.utc),
                "removida_por": admin.id,
            },
            synchronize_session=False,
        )
    )
    if n == 0:
        raise HTTPException(status_code=404, detail="Identidade não encontrada.")
    db.commit()
    return Response(status_code=204)
