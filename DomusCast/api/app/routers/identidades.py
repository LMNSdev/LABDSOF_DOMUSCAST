"""US-15: o residente entra com o token do QR code da fração e o seu nome.

O token só é validado aqui, por isso a fração só é revelada depois de criada a
identidade. A credencial devolvida fica no telemóvel; o servidor guarda o hash.
"""

import unicodedata

from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from .. import models, rate_limit, schemas
from ..database import get_db
from ..erros import ErroApi
from ..security import gerar_token, hash_token

router = APIRouter()

MAX_IDENTIDADES_POR_FRACAO = 10
JANELA_S = 3600
TENTATIVAS_POR_QR = 30
TOKENS_INVALIDOS_POR_IP = 20


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
    db: Session = Depends(get_db),
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
        raise ErroApi(409, "nome_duplicado", "Já existe alguém com este nome na sua fração.")

    credencial = gerar_token()
    identidade = models.Identidade(
        fracao_id=qr.fracao_id,
        qr_token_id=qr.id,
        nome=dados.nome,
        nome_normalizado=nome_normalizado,
        credencial_hash=hash_token(credencial),
    )
    db.add(identidade)
    db.commit()

    return schemas.IdentidadeCriada(
        id=identidade.id,
        nome=identidade.nome,
        fracao=qr.fracao.designacao,
        credencial=credencial,
    )
