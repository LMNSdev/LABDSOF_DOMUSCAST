"""US-10: upload, consulta privada, idempotência e estados do áudio."""

from datetime import datetime, timedelta, timezone
from io import BytesIO
import wave

import pytest
from sqlalchemy.exc import OperationalError

from app import models
from app.routers import atas
from tests.test_reunioes import _admin, _agendar, _auth, _residente


def _wav(amostras: int = 16) -> bytes:
    saida = BytesIO()
    with wave.open(saida, "wb") as audio:
        audio.setnchannels(1)
        audio.setsampwidth(2)
        audio.setframerate(16000)
        audio.writeframes(b"\0\0" * amostras)
    return saida.getvalue()


def _enviar(client, reuniao_id: int, token: str, conteudo: bytes | None = None, nome="ata.wav"):
    return client.post(
        f"/reunioes/{reuniao_id}/ata/audio",
        headers=_auth(token),
        files={"audio": (nome, _wav() if conteudo is None else conteudo, "audio/wav")},
    )


def test_upload_cria_ata_e_job_sem_esperar_pela_ia(client, db, tmp_path, monkeypatch):
    monkeypatch.setattr(atas, "MEDIA_ROOT", tmp_path)
    _, token = _admin(db)
    reuniao_id = _agendar(client, token).json()["id"]

    resposta = _enviar(client, reuniao_id, token)

    assert resposta.status_code == 202
    dados = resposta.json()
    assert dados["estado"] == "a_transcrever"
    assert dados["origem"] == "ia"
    assert dados["audio_guardado"] is True
    assert dados["transcricao"] is None
    ata = db.get(models.Ata, dados["id"])
    assert (tmp_path / ata.audio_path).read_bytes() == _wav()
    job = db.query(models.Job).filter_by(chave_idempotencia=f"transcrever:{ata.id}").one()
    assert job.estado == models.EstadoJob.pendente
    assert job.request_id == resposta.headers["X-Request-ID"]
    consulta = client.get(f"/reunioes/{reuniao_id}/ata", headers=_auth(token))
    assert consulta.json() == dados
    assert consulta.headers["cache-control"] == "private, no-store"


def test_reenvio_reutiliza_ata_e_job_e_reinicia_falha(client, db, tmp_path, monkeypatch):
    monkeypatch.setattr(atas, "MEDIA_ROOT", tmp_path)
    _, token = _admin(db)
    reuniao_id = _agendar(client, token).json()["id"]
    primeiro = _enviar(client, reuniao_id, token).json()
    ata = db.get(models.Ata, primeiro["id"])
    job = db.query(models.Job).filter_by(chave_idempotencia=f"transcrever:{ata.id}").one()

    assert _enviar(client, reuniao_id, token).json()["id"] == ata.id
    assert db.query(models.Job).filter_by(chave_idempotencia=f"transcrever:{ata.id}").count() == 1
    ata.estado = models.EstadoAta.falhou_transcricao
    job.estado = models.EstadoJob.falhou
    job.tentativas = 5
    db.commit()

    repetido = _enviar(client, reuniao_id, token)
    assert repetido.status_code == 202
    assert repetido.json()["estado"] == "a_transcrever"
    db.refresh(job)
    assert job.tentativas == 0
    assert job.estado == models.EstadoJob.pendente
    assert db.query(models.Ata).filter_by(reuniao_id=reuniao_id).count() == 1
    assert db.query(models.Job).filter_by(chave_idempotencia=f"transcrever:{ata.id}").count() == 1
    assert _enviar(client, reuniao_id, token, _wav(32)).status_code == 409
    assert (tmp_path / ata.audio_path).exists()


def test_repetir_a_partir_do_audio_guardado_sem_novo_upload(client, db, tmp_path, monkeypatch):
    monkeypatch.setattr(atas, "MEDIA_ROOT", tmp_path)
    admin, token = _admin(db)
    reuniao_id = _agendar(client, token).json()["id"]
    ata_id = _enviar(client, reuniao_id, token).json()["id"]
    ata = db.get(models.Ata, ata_id)
    job = db.query(models.Job).filter_by(chave_idempotencia=f"transcrever:{ata_id}").one()
    ata.estado = models.EstadoAta.falhou_transcricao
    ata.transcricao = "Transcrição já guardada antes da falha do rascunho."
    job.estado = models.EstadoJob.falhou
    job.tentativas = 5
    job.erro = "duracao_audio_invalida"
    db.commit()

    consulta = client.get(f"/reunioes/{reuniao_id}/ata", headers=_auth(token))
    assert consulta.json()["erro_transcricao"] == "duracao_audio_invalida"

    url = f"/reunioes/{reuniao_id}/ata/repetir"
    resposta = client.post(url, headers=_auth(token))
    assert resposta.status_code == 202
    assert resposta.headers["cache-control"] == "private, no-store"
    assert resposta.json()["estado"] == "a_transcrever"
    assert resposta.json()["audio_guardado"] is True
    assert client.post(url, headers=_auth(token)).status_code == 202
    db.refresh(ata)
    db.refresh(job)
    assert ata.transcricao == "Transcrição já guardada antes da falha do rascunho."
    assert job.estado == models.EstadoJob.pendente
    assert job.tentativas == 0
    assert job.request_id == resposta.headers["X-Request-ID"]
    assert db.query(models.Ata).filter_by(reuniao_id=reuniao_id).count() == 1
    assert db.query(models.Job).filter_by(chave_idempotencia=f"transcrever:{ata_id}").count() == 1
    assert (tmp_path / ata.audio_path).read_bytes() == _wav()

    residente = _residente(db, db.get(models.Condominio, admin.condominio_id))
    _, outro_admin = _admin(db)
    assert client.post(url, headers=_auth(residente)).status_code == 403
    assert client.post(url, headers=_auth(outro_admin)).status_code == 404
    assert client.post(url).status_code == 401


def test_audio_invalido_pode_ser_substituido_apos_falha(client, db, tmp_path, monkeypatch):
    monkeypatch.setattr(atas, "MEDIA_ROOT", tmp_path)
    _, token = _admin(db)
    reuniao_id = _agendar(client, token).json()["id"]
    ata_id = _enviar(client, reuniao_id, token).json()["id"]
    ata = db.get(models.Ata, ata_id)
    antigo = tmp_path / ata.audio_path
    job = db.query(models.Job).filter_by(chave_idempotencia=f"transcrever:{ata_id}").one()
    ata.estado = models.EstadoAta.falhou_transcricao
    ata.transcricao = "Texto parcial antigo"
    job.estado = models.EstadoJob.falhou
    job.erro = "audio_invalido"
    db.commit()

    novo = _enviar(client, reuniao_id, token, _wav(32))
    assert novo.status_code == 202
    assert novo.json()["id"] == ata_id
    db.refresh(ata)
    db.refresh(job)
    assert ata.estado == models.EstadoAta.a_transcrever
    assert ata.transcricao is None
    assert (tmp_path / ata.audio_path).read_bytes() == _wav(32)
    assert not antigo.exists()
    assert job.estado == models.EstadoJob.pendente
    assert job.tentativas == 0
    assert job.erro is None
    assert db.query(models.Ata).filter_by(reuniao_id=reuniao_id).count() == 1
    assert db.query(models.Job).filter_by(chave_idempotencia=f"transcrever:{ata_id}").count() == 1


def test_repetir_recusa_ata_aprovada_sem_falha_ou_audio(client, db, tmp_path, monkeypatch):
    monkeypatch.setattr(atas, "MEDIA_ROOT", tmp_path)
    _, token = _admin(db)
    reuniao_id = _agendar(client, token).json()["id"]
    url = f"/reunioes/{reuniao_id}/ata/repetir"
    assert client.post(url, headers=_auth(token)).status_code == 404
    ata_id = _enviar(client, reuniao_id, token).json()["id"]
    ata = db.get(models.Ata, ata_id)
    ata.estado = models.EstadoAta.pendente_revisao
    db.commit()
    assert client.post(url, headers=_auth(token)).json()["codigo"] == "ata_nao_falhou"
    ata.estado = models.EstadoAta.falhou_transcricao
    db.commit()
    (tmp_path / ata.audio_path).unlink()
    assert client.post(url, headers=_auth(token)).json()["codigo"] == "audio_em_falta"
    ata.estado = models.EstadoAta.aprovada
    db.commit()
    assert client.post(url, headers=_auth(token)).json()["codigo"] == "ata_ja_aprovada"


def test_audio_aprovado_nao_pode_ser_substituido(client, db, tmp_path, monkeypatch):
    monkeypatch.setattr(atas, "MEDIA_ROOT", tmp_path)
    _, token = _admin(db)
    reuniao_id = _agendar(client, token).json()["id"]
    ata_id = _enviar(client, reuniao_id, token).json()["id"]
    ata = db.get(models.Ata, ata_id)
    ata.estado = models.EstadoAta.aprovada
    db.commit()
    resposta = _enviar(client, reuniao_id, token)
    assert resposta.status_code == 409
    assert resposta.json()["codigo"] == "ata_ja_aprovada"


def test_apenas_admin_do_condominio_consulta_e_carrega(client, db, tmp_path, monkeypatch):
    monkeypatch.setattr(atas, "MEDIA_ROOT", tmp_path)
    admin, token = _admin(db)
    reuniao_id = _agendar(client, token).json()["id"]
    residente = _residente(db, db.get(models.Condominio, admin.condominio_id))
    _, outro_admin = _admin(db)
    assert _enviar(client, reuniao_id, residente).status_code == 403
    assert _enviar(client, reuniao_id, outro_admin).status_code == 404
    assert _enviar(client, reuniao_id, token).status_code == 202
    assert client.get(f"/reunioes/{reuniao_id}/ata", headers=_auth(residente)).status_code == 403
    assert client.get(f"/reunioes/{reuniao_id}/ata", headers=_auth(outro_admin)).status_code == 404
    assert client.get(f"/reunioes/{reuniao_id}/ata").status_code == 401
    assert client.get("/reunioes/999999/ata", headers=_auth(token)).status_code == 404


def test_audio_original_so_esta_disponivel_ao_admin_antes_da_aprovacao(client, db, tmp_path, monkeypatch):
    monkeypatch.setattr(atas, "MEDIA_ROOT", tmp_path)
    admin, token = _admin(db)
    reuniao_id = _agendar(client, token).json()["id"]
    residente = _residente(db, db.get(models.Condominio, admin.condominio_id))
    _, outro_admin = _admin(db)
    ata_id = _enviar(client, reuniao_id, token).json()["id"]
    url = f"/reunioes/{reuniao_id}/ata/audio"

    resposta = client.get(url, headers=_auth(token))
    assert resposta.status_code == 200
    assert resposta.content == _wav()
    assert resposta.headers["cache-control"] == "private, no-store"
    assert client.get(url, headers=_auth(residente)).status_code == 403
    assert client.get(url, headers=_auth(outro_admin)).status_code == 404
    assert client.get(url).status_code == 401
    ata = db.get(models.Ata, ata_id)
    ata.estado = models.EstadoAta.aprovada
    db.commit()
    assert client.get(url, headers=_auth(token)).status_code == 404


def test_formato_tamanho_e_pedido_invalidos(client, db, tmp_path, monkeypatch):
    monkeypatch.setattr(atas, "MEDIA_ROOT", tmp_path)
    _, token = _admin(db)
    reuniao_id = _agendar(client, token).json()["id"]
    assert _enviar(client, reuniao_id, token, b"", "vazio.wav").status_code == 422
    assert _enviar(client, reuniao_id, token, b"texto", "ata.txt").status_code == 415
    assert _enviar(client, reuniao_id, token, b"texto", "ata.wav").status_code == 415
    monkeypatch.setattr(atas, "MAX_AUDIO_BYTES", 32)
    assert _enviar(client, reuniao_id, token).status_code == 413
    assert db.query(models.Ata).filter_by(reuniao_id=reuniao_id).count() == 0
    assert list((tmp_path / "atas").glob("*")) == []


@pytest.mark.parametrize("metodo", ["get", "post"])
def test_base_indisponivel_devolve_503(client, db, tmp_path, monkeypatch, metodo):
    monkeypatch.setattr(atas, "MEDIA_ROOT", tmp_path)
    _, token = _admin(db)
    reuniao_id = _agendar(client, token).json()["id"]
    original = db.query

    def falhar_ata(modelo, *args):
        if modelo is models.Ata:
            raise OperationalError("SELECT", {}, Exception("BD indisponível"))
        return original(modelo, *args)

    monkeypatch.setattr(db, "query", falhar_ata)
    if metodo == "get":
        resposta = client.get(f"/reunioes/{reuniao_id}/ata", headers=_auth(token))
    else:
        resposta = _enviar(client, reuniao_id, token)
    assert resposta.status_code == 503
    assert resposta.json()["codigo"] == "servico_indisponivel"


def test_admin_pode_consultar_reuniao_passada_para_anexar_audio(client, db):
    admin, token = _admin(db)
    db.add(models.Reuniao(
        condominio_id=admin.condominio_id,
        data_hora=datetime.now(timezone.utc) - timedelta(days=2),
        local="Assembleia anterior",
    ))
    db.commit()
    assert client.get("/reunioes", headers=_auth(token)).json() == []
    resposta = client.get("/reunioes?incluir_passadas=true", headers=_auth(token))
    assert resposta.status_code == 200
    assert len(resposta.json()) == 1
    residente = _residente(db, db.get(models.Condominio, admin.condominio_id))
    assert client.get("/reunioes?incluir_passadas=true", headers=_auth(residente)).status_code == 403
