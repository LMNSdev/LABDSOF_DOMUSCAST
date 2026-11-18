"""Erros no formato de 8.4: `{codigo, mensagem, request_id}`.

Introduzido na US-15, que precisa do `codigo` para a app distinguir os dois 409.
As rotas anteriores ainda respondem com o `{"detail": ...}` do FastAPI.
"""

import uuid

from fastapi import Request
from fastapi.responses import JSONResponse


class ErroApi(Exception):
    def __init__(self, status: int, codigo: str, mensagem: str):
        self.status = status
        self.codigo = codigo
        self.mensagem = mensagem


# FastAPI resolve exception handlers by awaiting this callback.
async def tratar_erro_api(_: Request, erro: ErroApi) -> JSONResponse:  # NOSONAR
    return JSONResponse(
        status_code=erro.status,
        content={"codigo": erro.codigo, "mensagem": erro.mensagem, "request_id": uuid.uuid4().hex},
    )
