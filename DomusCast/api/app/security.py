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


def exigir_admin_do_condominio(admin: models.Administrador, condominio_id: int) -> None:
    if admin.condominio_id != condominio_id:
        raise HTTPException(status_code=403, detail="Sem acesso a este condomínio.")
