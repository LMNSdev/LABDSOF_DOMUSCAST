from datetime import timedelta

import pytest
from sqlalchemy.exc import OperationalError

from app import models
from app.security import hash_token
from tests.test_reportes import _criar_residente, auth, criar_duas_sessoes_na_mesma_fracao, criar_sessao, reportar


def test_filtros_ordem_e_privacidade(client, db):
    admin, residente_a, residente_b, fracao = criar_duas_sessoes_na_mesma_fracao(client)
    a = reportar(client, residente_a, "Elevador", mostrar_nome="false").json()
    b = reportar(client, residente_b, "Garagem", mostrar_nome="true").json()
    modelo_a = db.get(models.Reporte, a["id"])
    modelo_b = db.get(models.Reporte, b["id"])
    modelo_a.atualizado_em = modelo_b.atualizado_em + timedelta(hours=1)
    modelo_b.estado = models.EstadoReporte.em_curso
    db.commit()

    todos = client.get("/reportes", headers=auth(residente_b)).json()
    assert [r["id"] for r in todos] == [a["id"], b["id"]]
    assert todos[0]["autor_nome"] is None
    assert all(r["fracao"] is None for r in todos)
    assert [r["id"] for r in client.get(
        "/reportes?filtro=meus&estado=em_curso", headers=auth(residente_b)
    ).json()] == [b["id"]]
    assert client.get("/reportes?estado=resolvido", headers=auth(residente_b)).json() == []

    do_admin = client.get("/reportes?estado=aberto", headers=auth(admin)).json()
    assert [r["id"] for r in do_admin] == [a["id"]]
    assert do_admin[0]["fracao"] == fracao["designacao"]
    assert do_admin[0]["autor_nome"] == "Marta Silva"
    assert client.get("/reportes?filtro=meus", headers=auth(admin)).status_code == 422


def test_detalhe_historico_e_isolamento(client, db):
    admin, residente, _, _ = criar_duas_sessoes_na_mesma_fracao(client)
    criado = reportar(client, residente, "Fuga", mostrar_nome="false").json()
    modelo = db.get(models.Reporte, criado["id"])
    administrador = db.query(models.Administrador).filter_by(credencial_hash=hash_token(admin)).one()
    db.add(models.ReporteHistorico(
        reporte_id=modelo.id, estado_anterior=models.EstadoReporte.aberto,
        estado_novo=models.EstadoReporte.em_curso, nota="Técnico agendado",
        autor_tipo="administrador", autor_id=administrador.id,
        criado_em=modelo.criado_em + timedelta(days=1),
    ))
    db.commit()
    outro_admin, outro_residente, _, _ = criar_sessao(client)

    detalhe = client.get(f"/reportes/{criado['id']}", headers=auth(residente))
    assert detalhe.status_code == 200
    assert detalhe.json()["historico"][0]["estado_novo"] == "aberto"
    assert detalhe.json()["historico"][0]["autor_tipo"] == "sistema"
    assert detalhe.json()["historico"][1]["nota"] == "Técnico agendado"
    assert detalhe.json()["fracao"] is None
    assert client.get(f"/reportes/{criado['id']}", headers=auth(admin)).status_code == 200
    for token in (outro_admin, outro_residente):
        assert client.get(f"/reportes/{criado['id']}", headers=auth(token)).status_code == 404
    assert client.get(f"/reportes/{criado['id']}").status_code == 401
    assert client.get("/reportes/999999", headers=auth(residente)).status_code == 404


def test_co_reporter_aparece_em_meus(client, db):
    _, residente_a, residente_b, _ = criar_duas_sessoes_na_mesma_fracao(client)
    criado = reportar(client, residente_a, "Elevador").json()
    identidade_b = db.query(models.Identidade).filter_by(nome="Rui Costa").order_by(models.Identidade.id.desc()).first()
    db.add(models.ReporteSeguidor(
        reporte_id=criado["id"], identidade_id=identidade_b.id,
        tipo=models.TipoSeguidor.co_reporter,
    ))
    db.commit()
    meus = client.get("/reportes?filtro=meus", headers=auth(residente_b)).json()
    assert criado["id"] in [r["id"] for r in meus]


def test_foto_autenticada(client, db, tmp_path, monkeypatch):
    from app.routers import reportes as router
    from tests.test_reportes import _form, _headers, _imagem

    monkeypatch.setattr(router, "MEDIA_ROOT", tmp_path)
    _, residente, _, _ = criar_duas_sessoes_na_mesma_fracao(client)
    criado = client.post("/reportes", headers=_headers(residente), files={
        **_form("Foto", foto_alt="Água no chão"),
        "foto": ("foto.jpg", _imagem(), "image/jpeg"),
    }).json()
    detalhe = client.get(f"/reportes/{criado['id']}", headers=auth(residente)).json()
    assert detalhe["foto_alt"] == "Água no chão"
    assert detalhe["foto_url"] == f"/reportes/{criado['id']}/foto"
    foto = client.get(detalhe["foto_url"], headers=auth(residente))
    assert foto.status_code == 200
    assert foto.headers["cache-control"] == "private, no-store"
    assert foto.content[:2] == b"\xff\xd8"
    assert client.get(detalhe["foto_url"]).status_code == 401
    from tests.test_reportes import _criar_residente
    _, outro_residente = _criar_residente(db)
    assert client.get(detalhe["foto_url"], headers=auth(outro_residente)).status_code == 404


def test_foto_ausente_devolve_404(client, db):
    _, residente = _criar_residente(db)
    criado = reportar(client, residente, "Sem foto").json()
    assert client.get(f"/reportes/{criado['id']}/foto", headers=auth(residente)).status_code == 404


@pytest.mark.parametrize("sufixo", ["", "/1"])
def test_consulta_com_base_indisponivel_devolve_503(client, db, monkeypatch, sufixo):
    _, residente = _criar_residente(db)
    consulta_original = db.query

    def falhar_so_reportes(modelo, *args):
        if modelo is models.Reporte:
            raise OperationalError("SELECT", {}, Exception("ligação perdida"))
        return consulta_original(modelo, *args)

    monkeypatch.setattr(db, "query", falhar_so_reportes)
    resposta = client.get(f"/reportes{sufixo}", headers=auth(residente))
    assert resposta.status_code == 503
    assert resposta.json()["codigo"] == "servico_indisponivel"
