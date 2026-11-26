"""US-05: o administrador muda o estado de um reporte e o histórico fica auditável."""

import pytest
from sqlalchemy.exc import OperationalError

from app import models, rate_limit
from app.routers import reportes as router
from app.security import hash_token
from tests.test_reportes import auth, criar_duas_sessoes_na_mesma_fracao, criar_sessao, reportar


@pytest.fixture(autouse=True)
def limpar_rate_limit():
    # Cada teste cria um condomínio; o limite de pedidos não deve passar de um teste para o outro.
    rate_limit.reset()
    yield
    rate_limit.reset()


def _mudar(client, credencial, reporte_id, estado, nota="Técnico contactado"):
    return client.patch(
        f"/reportes/{reporte_id}/estado",
        headers=auth(credencial),
        json={"estado": estado, "nota": nota},
    )


def _preparar(client):
    admin, residente, _, _ = criar_duas_sessoes_na_mesma_fracao(client)
    reporte = reportar(client, residente, "Fuga de água na garagem").json()
    return admin, residente, reporte["id"]


def _historico(db, reporte_id):
    db.expire_all()
    return [
        (h.id, h.estado_anterior, h.estado_novo, h.nota, h.autor_tipo, h.autor_id)
        for h in db.query(models.ReporteHistorico)
        .filter_by(reporte_id=reporte_id)
        .order_by(models.ReporteHistorico.id)
    ]


def test_transicoes_validas_ficam_no_historico(client, db):
    admin, residente, reporte_id = _preparar(client)
    administrador = db.query(models.Administrador).filter_by(credencial_hash=hash_token(admin)).one()

    em_curso = _mudar(client, admin, reporte_id, "em_curso", "  Técnico contactado  ")
    assert em_curso.status_code == 200
    assert em_curso.json()["estado"] == "em_curso"
    assert em_curso.json()["historico"][-1]["nota"] == "Técnico contactado"
    assert em_curso.json()["historico"][-1]["autor_tipo"] == "administrador"

    resolvido = _mudar(client, admin, reporte_id, "resolvido", "Cano substituído")
    assert resolvido.status_code == 200
    assert [h["estado_novo"] for h in resolvido.json()["historico"]] == ["aberto", "em_curso", "resolvido"]

    historico = _historico(db, reporte_id)
    assert [(h[1], h[2], h[3], h[4], h[5]) for h in historico] == [
        (None, models.EstadoReporte.aberto, None, "sistema", None),
        (models.EstadoReporte.aberto, models.EstadoReporte.em_curso, "Técnico contactado", "administrador", administrador.id),
        (models.EstadoReporte.em_curso, models.EstadoReporte.resolvido, "Cano substituído", "administrador", administrador.id),
    ]

    # O residente vê a mudança na lista e no detalhe (US-03).
    detalhe = client.get(f"/reportes/{reporte_id}", headers=auth(residente)).json()
    assert detalhe["estado"] == "resolvido"
    assert detalhe["historico"][-1]["nota"] == "Cano substituído"
    lista = client.get("/reportes?estado=resolvido", headers=auth(residente)).json()
    assert [r["id"] for r in lista] == [reporte_id]


@pytest.mark.parametrize(
    ("passos", "pedido", "codigo"),
    [
        ([], "resolvido", "transicao_invalida"),
        ([], "aberto", "transicao_invalida"),
        (["em_curso"], "em_curso", "transicao_invalida"),
        (["em_curso"], "aberto", "transicao_invalida"),
        (["em_curso", "resolvido"], "resolvido", "reporte_resolvido"),
        (["em_curso", "resolvido"], "aberto", "reporte_resolvido"),
    ],
)
def test_transicoes_recusadas_nao_mudam_nada(client, db, passos, pedido, codigo):
    admin, _, reporte_id = _preparar(client)
    for passo in passos:
        assert _mudar(client, admin, reporte_id, passo).status_code == 200
    antes = _historico(db, reporte_id)

    resposta = _mudar(client, admin, reporte_id, pedido)

    assert resposta.status_code == 409
    assert resposta.json()["codigo"] == codigo
    assert resposta.json()["request_id"]
    assert _historico(db, reporte_id) == antes


@pytest.mark.parametrize(
    "corpo",
    [
        {"estado": "em_curso", "nota": ""},
        {"estado": "em_curso", "nota": "   "},
        {"estado": "em_curso", "nota": "x" * 501},
        {"estado": "em_curso"},
        {"nota": "Sem estado"},
        {"estado": "fechado", "nota": "Estado desconhecido"},
        {"estado": "em_curso", "nota": "Ok", "autor_id": 1},
    ],
)
def test_campos_invalidos_devolvem_422(client, db, corpo):
    admin, _, reporte_id = _preparar(client)
    resposta = client.patch(f"/reportes/{reporte_id}/estado", headers=auth(admin), json=corpo)
    assert resposta.status_code == 422
    assert resposta.json()["codigo"] == "dados_invalidos"
    assert len(_historico(db, reporte_id)) == 1


def test_nota_com_500_caracteres_e_aceite(client):
    admin, _, reporte_id = _preparar(client)
    resposta = _mudar(client, admin, reporte_id, "em_curso", "x" * 500)
    assert resposta.status_code == 200
    assert resposta.json()["historico"][-1]["nota"] == "x" * 500


def test_autorizacao_e_isolamento_do_condominio(client, db):
    admin, residente, reporte_id = _preparar(client)
    outro_admin, _, _, _ = criar_sessao(client)

    sem_credencial = client.patch(f"/reportes/{reporte_id}/estado", json={"estado": "em_curso", "nota": "x"})
    assert sem_credencial.status_code == 401
    assert _mudar(client, residente, reporte_id, "em_curso").status_code == 403
    assert _mudar(client, outro_admin, reporte_id, "em_curso").status_code == 404
    assert _mudar(client, admin, 999999, "em_curso").status_code == 404
    assert len(_historico(db, reporte_id)) == 1


def test_historico_anterior_nao_e_alterado(client, db):
    admin, _, reporte_id = _preparar(client)
    _mudar(client, admin, reporte_id, "em_curso", "Primeira nota")
    antes = _historico(db, reporte_id)

    _mudar(client, admin, reporte_id, "resolvido", "Segunda nota")

    depois = _historico(db, reporte_id)
    assert depois[: len(antes)] == antes
    assert len(depois) == len(antes) + 1


def test_mudanca_concorrente_devolve_409_sem_entrada_duplicada(client, db, monkeypatch):
    admin, _, reporte_id = _preparar(client)
    original = router.registar_mudanca_estado

    def outro_admin_chega_primeiro(sessao, rid, anterior, novo, nota, quem):
        # Simula outro administrador a gravar a mesma mudança entre a leitura e o update.
        assert original(sessao, rid, anterior, novo, "Outro administrador", quem)
        sessao.commit()
        return original(sessao, rid, anterior, novo, nota, quem)

    monkeypatch.setattr(router, "registar_mudanca_estado", outro_admin_chega_primeiro)
    resposta = _mudar(client, admin, reporte_id, "em_curso")

    assert resposta.status_code == 409
    assert resposta.json()["codigo"] == "transicao_invalida"
    notas = [h[3] for h in _historico(db, reporte_id)]
    assert notas == [None, "Outro administrador"]


def test_falha_da_base_de_dados_devolve_503_sem_mudar_estado(client, db, monkeypatch):
    admin, _, reporte_id = _preparar(client)

    def falhar():
        raise OperationalError("COMMIT", {}, Exception("ligação perdida"))

    monkeypatch.setattr(db, "commit", falhar)
    resposta = _mudar(client, admin, reporte_id, "em_curso")
    monkeypatch.undo()

    assert resposta.status_code == 503
    assert resposta.json()["codigo"] == "servico_indisponivel"
    assert resposta.headers["retry-after"] == "5"
    db.expire_all()
    assert db.get(models.Reporte, reporte_id).estado == models.EstadoReporte.aberto
    assert len(_historico(db, reporte_id)) == 1
