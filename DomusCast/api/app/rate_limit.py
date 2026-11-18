"""Limite de pedidos, em memória (suficiente para uma instância da API).

Por IP na criação de condomínios (US-01, TM-09); por QR code na criação de
identidades (US-15). Um reinício da API limpa os contadores; com várias
instâncias seria preciso guardá-los num sítio partilhado.
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


def verificar(request: Request, chave: str, maximo: int, janela_s: int, por_ip: bool = True) -> None:
    """Levanta 429 se já houve `maximo` pedidos nos últimos `janela_s` segundos.

    Com `por_ip`, a contagem é separada por IP; sem ele, a `chave` conta para todos.
    """
    if por_ip:
        ip = request.client.host if request.client else "desconhecido"
        chave = f"{chave}:{ip}"
    agora = time.monotonic()
    with _lock:
        fila = _pedidos[chave]
        while fila and agora - fila[0] > janela_s:
            fila.popleft()
        if len(fila) >= maximo:
            raise HTTPException(status_code=429, detail="Demasiados pedidos. Tente mais tarde.")
        fila.append(agora)
