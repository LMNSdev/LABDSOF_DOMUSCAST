"""Tokens aleatórios e autenticação do administrador (ADR-008: credencial mock, autorização real)."""

import hashlib
import secrets

from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from . import models
from .database import get_db

_bearer = HTTPBearer(auto_error=False)


def gerar_token() -> str:
    """Token longo e não adivinhável (256 bits), sem relação com a fração ou o condomínio."""
    return secrets.token_urlsafe(32)


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def admin_atual(
    cred: HTTPAuthorizationCredentials | None = Depends(_bearer),
    db: Session = Depends(get_db),
) -> models.Administrador:
    """Administrador dono da credencial Bearer; 401 se faltar, for inválida ou foi removido."""
    if cred is None:
        raise HTTPException(status_code=401, detail="Credencial em falta.")
    admin = (
        db.query(models.Administrador)
        .filter(
            models.Administrador.credencial_hash == hash_token(cred.credentials),
            models.Administrador.removido_em.is_(None),
        )
        .first()
    )
    if admin is None:
        raise HTTPException(status_code=401, detail="Credencial inválida.")
    return admin


def identidade_atual(
    cred: HTTPAuthorizationCredentials | None = Depends(_bearer),
    db: Session = Depends(get_db),
) -> models.Identidade:
    """Identidade ativa do dispositivo; administradores não podem criar reportes."""
    if cred is None:
        raise HTTPException(status_code=401, detail="Credencial em falta.")

    credencial_hash = hash_token(cred.credentials)
    administrador = (
        db.query(models.Administrador)
        .filter(models.Administrador.credencial_hash == credencial_hash)
        .first()
    )
    if administrador is not None:
        if administrador.removido_em is not None:
            raise HTTPException(status_code=401, detail="Credencial inválida.")
        raise HTTPException(
            status_code=403, detail="Só residentes podem criar reportes."
        )

    identidade = (
        db.query(models.Identidade)
        .filter(
            models.Identidade.credencial_hash == credencial_hash,
        )
        .first()
    )
    if identidade is not None and identidade.removida_em is None:
        return identidade

    raise HTTPException(status_code=401, detail="Credencial inválida.")


def exigir_admin_do_condominio(admin: models.Administrador, condominio_id: int) -> None:
    if admin.condominio_id != condominio_id:
        raise HTTPException(status_code=403, detail="Sem acesso a este condomínio.")
