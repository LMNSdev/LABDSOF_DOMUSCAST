"""Simulador do serviço de calendário externo (US-28, 8.6 e ADR-007).

Imita um subconjunto da API de eventos do Google Calendar:

- `POST /calendars/{calendarId}/events` com `{id?, summary, location, start: {dateTime},
  end: {dateTime}}` devolve `200 {id, status: "confirmed", start, end}`. Erros: `400`
  (pedido inválido), `409` (já existe um evento com esse `id`), `429` (com
  `Retry-After`) e `503`.
- `GET /calendars/{calendarId}/events` lista os eventos (`{items: [...]}`), para mostrar
  que não há duplicados.
- `POST /_chaos` com `{modo, atraso_ms}` muda o comportamento; `GET /_chaos` mostra-o.

O `id` escolhido pelo cliente segue as regras do Google (base32hex: `a` a `v` e `0` a
`9`, 5 a 1024 caracteres); é o que permite ao Worker repetir sem duplicar eventos.
Corre num container próprio (docker-compose.yml) e guarda os eventos em memória.
"""

import asyncio
from enum import Enum
from typing import Annotated
from uuid import uuid4

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from pydantic import AwareDatetime, BaseModel, ConfigDict, Field, StringConstraints

ATRASO_LENTO_MS = 15_000
RETRY_AFTER_S = 30


class Modo(str, Enum):
    ok = "ok"
    indisponivel = "indisponivel"
    lento = "lento"
    incompleto = "incompleto"
    invalido = "invalido"
    # 429 com Retry-After: a outra forma de "atrasado" da tabela de 8.6.
    limite = "limite"


class Caos(BaseModel):
    model_config = ConfigDict(extra="forbid")

    modo: Modo
    atraso_ms: Annotated[int, Field(ge=0, le=60_000)] = ATRASO_LENTO_MS


class Quando(BaseModel):
    # Nome do campo no Google Calendar.
    dateTime: AwareDatetime


class Evento(BaseModel):
    id: Annotated[str, StringConstraints(pattern=r"^[a-v0-9]{5,1024}$")] | None = None
    summary: Annotated[str, StringConstraints(min_length=1, max_length=1024)]
    location: Annotated[str, StringConstraints(max_length=1024)] | None = None
    start: Quando
    end: Quando


class Estado:
    def __init__(self) -> None:
        self.limpar()

    def limpar(self) -> None:
        self.modo = Modo.ok
        self.atraso_ms = ATRASO_LENTO_MS
        self.eventos: dict[str, dict[str, dict]] = {}


estado = Estado()
app = FastAPI(title="Simulador de calendário (DomusCast)", version="0.1.0")


def _erro(status: int, mensagem: str, headers: dict[str, str] | None = None) -> JSONResponse:
    # Mesmo formato de erro do Google Calendar.
    return JSONResponse(
        status_code=status,
        headers=headers,
        content={"error": {"code": status, "message": mensagem}},
    )


@app.exception_handler(RequestValidationError)
async def pedido_invalido(_request: Request, _exc: RequestValidationError):
    return _erro(400, "Invalid request.")


@app.get("/health")
def health():
    return {"status": "ok", "modo": estado.modo}


@app.get("/_chaos")
def ver_caos():
    return {"modo": estado.modo, "atraso_ms": estado.atraso_ms}


@app.post("/_chaos")
def mudar_caos(caos: Caos):
    estado.modo = caos.modo
    estado.atraso_ms = caos.atraso_ms
    return ver_caos()


@app.get("/calendars/{calendar_id}/events")
def listar_eventos(calendar_id: str):
    return {"items": list(estado.eventos.get(calendar_id, {}).values())}


@app.post("/calendars/{calendar_id}/events")
async def criar_evento(calendar_id: str, evento: Evento):
    if estado.modo == Modo.indisponivel:
        return _erro(503, "Backend Error")
    if estado.modo == Modo.limite:
        return _erro(429, "Rate Limit Exceeded", {"Retry-After": str(RETRY_AFTER_S)})
    if estado.modo == Modo.lento:
        await asyncio.sleep(estado.atraso_ms / 1000)

    inicio = evento.start.dateTime.isoformat()
    fim = evento.end.dateTime.isoformat()
    if estado.modo == Modo.incompleto:
        return {"status": "confirmed", "end": {"dateTime": fim}}
    if estado.modo == Modo.invalido:
        return {
            "id": evento.id or uuid4().hex,
            "status": "confirmed",
            "start": {"dateTime": "2026-13-45T25:61:00"},
            "end": {"dateTime": fim},
        }

    if evento.end.dateTime <= evento.start.dateTime:
        return _erro(400, "The specified time range is empty.")
    eventos = estado.eventos.setdefault(calendar_id, {})
    evento_id = evento.id or uuid4().hex
    if evento_id in eventos:
        return _erro(409, "The requested identifier already exists.")
    criado = {
        "kind": "calendar#event",
        "id": evento_id,
        "status": "confirmed",
        "summary": evento.summary,
        "location": evento.location,
        "start": {"dateTime": inicio},
        "end": {"dateTime": fim},
    }
    eventos[evento_id] = criado
    return criado
