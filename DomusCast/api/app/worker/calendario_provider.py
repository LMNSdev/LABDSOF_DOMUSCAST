"""Cliente do serviço de calendário externo, usado só pelo Worker (US-28, 8.6).

`ServicoCalendarioProvider` publica uma reunião no simulador e valida a resposta.
Qualquer das quatro condições de 8.6 (indisponível, atrasado, incompleto, inválido),
um `400` ou um `429` dá `FalhaCalendario`; o Worker repete o job com backoff.
"""

from datetime import datetime, timedelta, timezone
from typing import Protocol

import httpx

from .. import models

TIMEOUT_S = 10.0
DURACAO_REUNIAO = timedelta(hours=2)
TITULO = "Assembleia de condóminos"


class FalhaCalendario(Exception):
    def __init__(self, motivo: str, retry_after_s: float | None = None) -> None:
        super().__init__(motivo)
        self.motivo = motivo
        self.retry_after_s = retry_after_s


class CalendarProvider(Protocol):
    def publicar(self, reuniao: models.Reuniao) -> str:
        """Publica a reunião e devolve o id do evento no calendário externo."""
        ...


def evento_id(reuniao: models.Reuniao) -> str:
    """Id do evento escolhido por nós: repetir a publicação não cria outro evento."""
    return f"domuscast{reuniao.id}"


def _data(valor: object) -> datetime | None:
    if not isinstance(valor, dict) or not isinstance(valor.get("dateTime"), str):
        return None
    return datetime.fromisoformat(valor["dateTime"])


def _retry_after(resposta: httpx.Response) -> float | None:
    try:
        return max(float(resposta.headers["Retry-After"]), 0.0)
    except (KeyError, ValueError):
        return None


def validar_resposta(corpo: object) -> str:
    """Devolve o `id` de uma resposta `200 {id, status, start, end}` coerente."""
    if not isinstance(corpo, dict):
        raise FalhaCalendario("invalido: a resposta não é um objeto JSON")
    em_falta = [c for c in ("id", "status", "start", "end") if not corpo.get(c)]
    if em_falta:
        raise FalhaCalendario(f"incompleto: faltam {', '.join(em_falta)}")
    if not isinstance(corpo["id"], str) or corpo["status"] != "confirmed":
        raise FalhaCalendario("invalido: id ou status inesperados")
    try:
        inicio, fim = _data(corpo["start"]), _data(corpo["end"])
    except ValueError as exc:
        raise FalhaCalendario("invalido: datas mal formadas") from exc
    if inicio is None or fim is None:
        raise FalhaCalendario("incompleto: start ou end sem dateTime")
    if inicio.tzinfo is None or fim.tzinfo is None:
        raise FalhaCalendario("invalido: datas sem fuso")
    if fim <= inicio:
        raise FalhaCalendario("invalido: end não é depois de start")
    return corpo["id"]


class ServicoCalendarioProvider:
    def __init__(self, base_url: str, client: httpx.Client | None = None) -> None:
        self._client = client or httpx.Client(base_url=base_url, timeout=TIMEOUT_S)

    def publicar(self, reuniao: models.Reuniao) -> str:
        inicio = reuniao.data_hora
        if inicio.tzinfo is None:
            # O SQLite dos testes devolve datas sem fuso; estão gravadas em UTC.
            inicio = inicio.replace(tzinfo=timezone.utc)
        corpo = {
            "id": evento_id(reuniao),
            "summary": TITULO,
            "location": reuniao.local,
            "start": {"dateTime": inicio.isoformat()},
            "end": {"dateTime": (inicio + DURACAO_REUNIAO).isoformat()},
        }
        url = f"/calendars/condominio{reuniao.condominio_id}/events"
        try:
            resposta = self._client.post(url, json=corpo, timeout=TIMEOUT_S)
        except httpx.TimeoutException as exc:
            raise FalhaCalendario(f"atrasado: sem resposta em {TIMEOUT_S:.0f} s") from exc
        except httpx.TransportError as exc:
            raise FalhaCalendario(f"indisponivel: {type(exc).__name__}") from exc

        if resposta.status_code == 409:
            # Já publicado numa tentativa anterior (o Worker caiu antes de gravar).
            return corpo["id"]
        if resposta.status_code == 429:
            raise FalhaCalendario("atrasado: 429", _retry_after(resposta))
        if resposta.status_code >= 500:
            raise FalhaCalendario(f"indisponivel: {resposta.status_code}")
        if resposta.status_code != 200:
            raise FalhaCalendario(f"recusado: {resposta.status_code}")
        try:
            dados = resposta.json()
        except ValueError as exc:
            raise FalhaCalendario("invalido: a resposta não é JSON") from exc
        return validar_resposta(dados)
