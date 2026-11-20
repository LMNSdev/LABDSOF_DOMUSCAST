"""Erros no formato de 8.4: `{codigo, mensagem, request_id}`.

Introduzido na US-15, que precisa do `codigo` para a app distinguir os dois 409.
Desde a US-02, os handlers em `main.py` devolvem o mesmo formato para os
`HTTPException` e para os 422 de validação.
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
async def tratar_erro_api(request: Request, erro: ErroApi) -> JSONResponse:  # NOSONAR
    # O mesmo valor do cabeçalho X-Request-ID, definido pelo middleware em main.py.
    request_id = getattr(request.state, "request_id", None) or uuid.uuid4().hex
    return JSONResponse(
        status_code=erro.status,
        content={"codigo": erro.codigo, "mensagem": erro.mensagem, "request_id": request_id},
    )
