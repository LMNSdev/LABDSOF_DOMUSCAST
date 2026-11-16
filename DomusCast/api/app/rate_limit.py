"""Limite de pedidos por IP, em memória (suficiente para uma instância da API).

Usado na criação de condomínios (US-01, TM-09). Um reinício da API limpa os
contadores; com várias instâncias seria preciso guardá-los num sítio partilhado.
"""

import time
from collections import defaultdict, deque
from threading import Lock

from fastapi import HTTPException, Request

_pedidos: dict[str, deque[float]] = defaultdict(deque)
_lock = Lock()


def reset() -> None:
    with _lock:
        _pedidos.clear()


def verificar(request: Request, chave: str, maximo: int, janela_s: int) -> None:
    """Levanta 429 se o IP já fez `maximo` pedidos aceites nos últimos `janela_s` segundos."""
    ip = request.client.host if request.client else "desconhecido"
    agora = time.monotonic()
    with _lock:
        fila = _pedidos[f"{chave}:{ip}"]
        while fila and agora - fila[0] > janela_s:
            fila.popleft()
        if len(fila) >= maximo:
            raise HTTPException(status_code=429, detail="Demasiados pedidos. Tente mais tarde.")
        fila.append(agora)
