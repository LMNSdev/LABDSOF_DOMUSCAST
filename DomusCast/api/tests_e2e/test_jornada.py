"""T-06: testes end-to-end da jornada principal, contra a stack a correr (docker compose).

Falam só por HTTP com os containers reais: a API, o worker-calendario, o simulador do
calendário e o PostgreSQL. Não importam nada de `app`, ao contrário dos testes de `tests/`.

Variáveis de ambiente (sem `E2E_API_URL`, os testes são ignorados):
- `E2E_API_URL`: ex. http://localhost:8000
- `E2E_CALENDARIO_URL`: ex. http://localhost:8001 (simulador; testes da reunião)

O worker-calendario deve correr com `WORKER_BACKOFF_UNIDADE_S=1`, para as novas
tentativas demorarem segundos e não minutos.
"""

import os
import time
from datetime import datetime, timedelta, timezone
from uuid import uuid4

import httpx
import pytest

API_URL = os.getenv("E2E_API_URL")
CALENDARIO_URL = os.getenv("E2E_CALENDARIO_URL")

pytestmark = pytest.mark.skipif(
    not API_URL, reason="E2E_API_URL não definida: a stack não está a correr"
)

# O worker-calendario procura jobs de 2 em 2 s; com WORKER_BACKOFF_UNIDADE_S=1, as 5
# tentativas esgotam-se em cerca de 15 s (esperas de 1, 2, 4 e 8 s).
ESPERA_MAXIMA_S = 60


def _auth(credencial: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {credencial}"}


def _esperar(condicao, descricao: str, limite_s: float = ESPERA_MAXIMA_S):
    """Repete `condicao()` até devolver um valor verdadeiro ou passar o limite."""
    fim = time.monotonic() + limite_s
    while time.monotonic() < fim:
        valor = condicao()
        if valor:
            return valor
        time.sleep(1)
    pytest.fail(f"Passaram {limite_s} s sem {descricao}.")


@pytest.fixture(scope="module")
def api():
    with httpx.Client(base_url=API_URL, timeout=15) as cliente:
        yield cliente


@pytest.fixture(scope="module")
def calendario():
    if not CALENDARIO_URL:
        pytest.skip("E2E_CALENDARIO_URL não definida")
    with httpx.Client(base_url=CALENDARIO_URL, timeout=15) as cliente:
        yield cliente
        # Deixa o simulador como estava, mesmo que um teste falhe a meio.
        cliente.post("/_chaos", json={"modo": "ok"})


@pytest.fixture(scope="module")
def condominio(api):
    """Um condomínio por execução (POST /condominios tem limite de 5 por hora por IP)."""
    r = api.post(
        "/condominios",
        json={"nome": f"E2E {uuid4().hex[:8]}", "nome_admin": "Ana Admin", "n_fracoes": 2},
    )
    assert r.status_code == 201, r.text
    dados = r.json()
    return {"id": dados["id"], "admin": dados["credencial_admin"]}


@pytest.fixture(scope="module")
def residente(api, condominio):
    """US-01 e US-15: o administrador gera o QR code da fração e o residente entra com o nome."""
    admin = _auth(condominio["admin"])
    r = api.get(f"/condominios/{condominio['id']}/fracoes", headers=admin)
    assert r.status_code == 200, r.text
    fracao = r.json()[0]

    r = api.post(f"/fracoes/{fracao['id']}/qr", headers=admin)
    assert r.status_code == 201, r.text
    token = r.json()["token"]

    r = api.post("/identidades", json={"token": token, "nome": "Rui Residente"})
    assert r.status_code == 201, r.text
    dados = r.json()
    assert dados["fracao"] == fracao["designacao"]
    return {"credencial": dados["credencial"], "fracao": fracao["designacao"]}


def _reportar(api, credencial: str, descricao: str, chave: str) -> httpx.Response:
    # multipart sem ficheiro: o par (None, valor) força o multipart/form-data que a API exige.
    return api.post(
        "/reportes",
        headers={**_auth(credencial), "Idempotency-Key": chave},
        files={"descricao": (None, descricao)},
    )


def test_jornada_do_reporte(api, condominio, residente):
    """US-02, US-03, US-05 e US-09: reportar, acompanhar e resolver uma avaria."""
    admin = _auth(condominio["admin"])
    morador = _auth(residente["credencial"])
    descricao = f"Luz da escada fundida no 2.º andar ({uuid4().hex[:6]})"
    chave = str(uuid4())

    # Reportar; reenviar com a mesma chave devolve o mesmo reporte sem o duplicar.
    r = _reportar(api, residente["credencial"], descricao, chave)
    assert r.status_code == 201, r.text
    reporte = r.json()
    assert reporte["estado"] == "aberto"
    r = _reportar(api, residente["credencial"], descricao, chave)
    assert r.status_code == 200, r.text
    assert r.json()["id"] == reporte["id"]

    # O residente vê o reporte como seu, sem fração nem nome; o administrador vê os dois.
    r = api.get("/reportes", headers=morador)
    assert r.status_code == 200, r.text
    meus = [x for x in r.json() if x["id"] == reporte["id"]]
    assert len(meus) == 1
    assert meus[0]["meu"] is True
    assert meus[0]["fracao"] is None
    assert meus[0]["autor_nome"] is None

    r = api.get("/reportes", headers=admin)
    assert r.status_code == 200, r.text
    vista_admin = next(x for x in r.json() if x["id"] == reporte["id"])
    assert vista_admin["fracao"] == residente["fracao"]
    assert vista_admin["autor_nome"] == "Rui Residente"

    # Permissões: sem credencial 401; o residente não muda o estado (403).
    assert api.get("/reportes").status_code == 401
    r = api.patch(
        f"/reportes/{reporte['id']}/estado",
        headers=morador,
        json={"estado": "em_curso", "nota": "Tentativa do residente"},
    )
    assert r.status_code == 403, r.text

    # O administrador avança Aberto -> Em curso -> Resolvido.
    for estado, nota in (("em_curso", "Eletricista chamado"), ("resolvido", "Lâmpada trocada")):
        r = api.patch(
            f"/reportes/{reporte['id']}/estado",
            headers=admin,
            json={"estado": estado, "nota": nota},
        )
        assert r.status_code == 200, r.text
        assert r.json()["estado"] == estado

    # O residente vê-o resolvido, com o histórico completo.
    r = api.get(f"/reportes/{reporte['id']}", headers=morador)
    assert r.status_code == 200, r.text
    detalhe = r.json()
    assert detalhe["estado"] == "resolvido"
    estados = [h["estado_novo"] for h in detalhe["historico"]]
    assert sorted(estados) == ["aberto", "em_curso", "resolvido"]


def _agendar(api, condominio) -> dict:
    data_hora = (datetime.now(timezone.utc) + timedelta(days=7)).replace(microsecond=0)
    r = api.post(
        "/reunioes",
        headers=_auth(condominio["admin"]),
        json={"data_hora": data_hora.isoformat(), "local": f"Sala E2E {uuid4().hex[:6]}"},
    )
    assert r.status_code == 201, r.text
    reuniao = r.json()
    assert reuniao["estado_sync"] == "pendente"
    return reuniao


def _estado_sync(api, condominio, reuniao_id: int) -> str | None:
    r = api.get("/reunioes", headers=_auth(condominio["admin"]))
    assert r.status_code == 200, r.text
    return next((x["estado_sync"] for x in r.json() if x["id"] == reuniao_id), None)


def _eventos(calendario, condominio) -> list[dict]:
    r = calendario.get(f"/calendars/condominio{condominio['id']}/events")
    assert r.status_code == 200, r.text
    return r.json()["items"]


def _pedidos(calendario, condominio) -> int:
    """Pedidos de criação que o simulador recebeu para o calendário do condomínio."""
    r = calendario.get("/_chaos")
    assert r.status_code == 200, r.text
    return r.json()["pedidos"].get(f"condominio{condominio['id']}", 0)


def test_reuniao_publicada_no_calendario(api, calendario, condominio, residente):
    """US-13 e US-28: workflow assíncrono e integração externa, com o simulador a responder."""
    assert calendario.post("/_chaos", json={"modo": "ok"}).status_code == 200
    reuniao = _agendar(api, condominio)

    _esperar(
        lambda: _estado_sync(api, condominio, reuniao["id"]) == "sincronizada",
        "a reunião ficar sincronizada",
    )
    assert any(e["id"] == f"domuscast{reuniao['id']}" for e in _eventos(calendario, condominio))

    # O residente também vê a reunião agendada.
    r = api.get("/reunioes", headers=_auth(residente["credencial"]))
    assert r.status_code == 200, r.text
    assert any(x["id"] == reuniao["id"] for x in r.json())


def test_calendario_indisponivel_passa_a_alternativo(api, calendario, condominio):
    """Condição de falha (8.6): com o serviço sempre em baixo, esgota as 5 tentativas."""
    assert calendario.post("/_chaos", json={"modo": "indisponivel"}).status_code == 200
    reuniao = _agendar(api, condominio)

    _esperar(
        lambda: _estado_sync(api, condominio, reuniao["id"]) == "alternativo",
        "a reunião passar a alternativo",
    )
    assert not any(e["id"] == f"domuscast{reuniao['id']}" for e in _eventos(calendario, condominio))
    calendario.post("/_chaos", json={"modo": "ok"})


def test_calendario_recupera_depois_de_falhar(api, calendario, condominio):
    """Condição de falha e recuperação: a primeira tentativa falha e uma seguinte publica."""
    assert calendario.post("/_chaos", json={"modo": "indisponivel"}).status_code == 200
    antes = _pedidos(calendario, condominio)
    reuniao = _agendar(api, condominio)

    # Espera que o Worker tente e falhe pelo menos uma vez (o simulador conta os pedidos
    # por calendário, também os que falham); a 5.ª tentativa só acontece cerca de 15 s
    # depois da 1.ª, por isso ainda há tentativas pela frente quando o serviço volta.
    _esperar(
        lambda: _pedidos(calendario, condominio) > antes,
        "uma tentativa do Worker com o serviço em baixo",
        limite_s=10,
    )
    assert _estado_sync(api, condominio, reuniao["id"]) == "pendente"

    assert calendario.post("/_chaos", json={"modo": "ok"}).status_code == 200
    _esperar(
        lambda: _estado_sync(api, condominio, reuniao["id"]) == "sincronizada",
        "a reunião ficar sincronizada depois de o serviço voltar",
    )
    assert any(e["id"] == f"domuscast{reuniao['id']}" for e in _eventos(calendario, condominio))
