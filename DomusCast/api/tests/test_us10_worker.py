"""Worker da US-10: ordem, retries, deduplicação e resposta tardia."""

import json
from datetime import datetime, timedelta, timezone
from pathlib import Path

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app import models
from app.database import Base
from app.worker.openai_provider import FalhaProvider, _formatar_rascunho
from app.worker.processor import limpar_audios_aprovados, processar_job, recuperar_jobs, reservar_job


@pytest.fixture
def trabalho(tmp_path):
    engine = create_engine(f"sqlite:///{tmp_path / 'worker.db'}")
    Base.metadata.create_all(engine)
    sessoes = sessionmaker(bind=engine)
    audio = tmp_path / "ata.wav"
    audio.write_bytes(b"audio-de-teste")
    with sessoes() as db:
        condominio = models.Condominio(nome="Prédio", n_fracoes=1)
        db.add(condominio)
        db.flush()
        reuniao = models.Reuniao(
            condominio_id=condominio.id,
            data_hora=datetime.now(timezone.utc),
            local="Sala",
        )
        db.add(reuniao)
        db.flush()
        ata = models.Ata(
            reuniao_id=reuniao.id,
            audio_path="ata.wav",
            origem=models.OrigemAta.ia,
            estado=models.EstadoAta.a_transcrever,
        )
        db.add(ata)
        db.flush()
        db.add(models.Job(
            tipo="publicar_calendario", chave_idempotencia=f"publicar_calendario:{reuniao.id}",
            payload=json.dumps({"reuniao_id": reuniao.id}),
        ))
        job = models.Job(
            tipo="transcrever", chave_idempotencia=f"transcrever:{ata.id}",
            payload=json.dumps({"ata_id": ata.id}), request_id="pedido-123",
        )
        db.add(job)
        db.commit()
        return sessoes, job.id, ata.id, tmp_path


class ProviderFalso:
    def __init__(self, falhar_transcricao=False, falhar_rascunho=False):
        self.falhar_transcricao = falhar_transcricao
        self.falhar_rascunho = falhar_rascunho
        self.chamadas_transcricao = 0
        self.chamadas_rascunho = 0

    def transcrever(self, caminho):
        self.chamadas_transcricao += 1
        assert caminho.read_bytes() == b"audio-de-teste"
        if self.falhar_transcricao:
            raise FalhaProvider("ia_indisponivel")
        return "Decidiram reparar a entrada."

    def gerar_rascunho(self, transcricao):
        self.chamadas_rascunho += 1
        assert transcricao == "Decidiram reparar a entrada."
        if self.falhar_rascunho:
            raise FalhaProvider("ia_indisponivel")
        return "Gerado por IA. Pendente de revisão. Reparar a entrada."


def test_worker_conclui_ata_sem_consumir_job_do_calendario(trabalho):
    sessoes, job_id, ata_id, raiz = trabalho
    provider = ProviderFalso()
    assert reservar_job(sessoes) == job_id
    processar_job(job_id, provider, sessoes, raiz)
    with sessoes() as db:
        ata = db.get(models.Ata, ata_id)
        assert ata.estado == models.EstadoAta.pendente_revisao
        assert ata.transcricao == "Decidiram reparar a entrada."
        assert ata.rascunho.startswith("Gerado por IA. Pendente de revisão.")
        assert (raiz / ata.audio_path).exists()
        assert db.get(models.Job, job_id).estado == models.EstadoJob.concluido
        assert db.query(models.Job).filter_by(tipo="publicar_calendario").one().estado == models.EstadoJob.pendente
    assert provider.chamadas_transcricao == 1
    assert provider.chamadas_rascunho == 1


def test_worker_falha_apos_cinco_tentativas_sem_apagar_audio(trabalho):
    sessoes, job_id, ata_id, raiz = trabalho
    provider = ProviderFalso(falhar_transcricao=True)
    for tentativa in range(1, 6):
        assert reservar_job(sessoes) == job_id
        processar_job(job_id, provider, sessoes, raiz)
        with sessoes() as db:
            job = db.get(models.Job, job_id)
            assert job.tentativas == tentativa
            assert job.erro == "ia_indisponivel"
            if tentativa < 5:
                assert job.estado == models.EstadoJob.pendente
                job.proxima_tentativa_em = datetime.now(timezone.utc) - timedelta(seconds=1)
                db.commit()
            else:
                assert job.estado == models.EstadoJob.falhou
                assert db.get(models.Ata, ata_id).estado == models.EstadoAta.falhou_transcricao
    assert provider.chamadas_transcricao == 5
    assert (raiz / "ata.wav").exists()


def test_retry_reutiliza_transcricao_ja_guardada(trabalho):
    sessoes, job_id, ata_id, raiz = trabalho
    provider = ProviderFalso(falhar_rascunho=True)
    assert reservar_job(sessoes) == job_id
    processar_job(job_id, provider, sessoes, raiz)
    with sessoes() as db:
        assert db.get(models.Ata, ata_id).transcricao is not None
        job = db.get(models.Job, job_id)
        job.proxima_tentativa_em = datetime.now(timezone.utc) - timedelta(seconds=1)
        db.commit()
    provider.falhar_rascunho = False
    assert reservar_job(sessoes) == job_id
    processar_job(job_id, provider, sessoes, raiz)
    assert provider.chamadas_transcricao == 1
    assert provider.chamadas_rascunho == 2


def test_resposta_tardia_nao_substitui_ata_aprovada(trabalho):
    sessoes, job_id, ata_id, raiz = trabalho

    class AprovacaoDuranteIA(ProviderFalso):
        def gerar_rascunho(self, transcricao):
            with sessoes() as db:
                ata = db.get(models.Ata, ata_id)
                ata.estado = models.EstadoAta.aprovada
                ata.texto_aprovado = "Texto confirmado pelo administrador"
                db.commit()
            return super().gerar_rascunho(transcricao)

    assert reservar_job(sessoes) == job_id
    processar_job(job_id, AprovacaoDuranteIA(), sessoes, raiz)
    with sessoes() as db:
        ata = db.get(models.Ata, ata_id)
        assert ata.texto_aprovado == "Texto confirmado pelo administrador"
        assert ata.rascunho is None
        # A transcrição pode ter sido guardada antes da aprovação, mas a
        # resposta tardia não acrescenta um rascunho nem muda o texto publicado.
        assert db.get(models.Job, job_id).estado == models.EstadoJob.concluido
    assert limpar_audios_aprovados(sessoes, raiz) == 1
    assert limpar_audios_aprovados(sessoes, raiz) == 0
    with sessoes() as db:
        ata = db.get(models.Ata, ata_id)
        assert ata.audio_path is None
        assert ata.transcricao is None
        assert ata.rascunho is None
        assert ata.texto_aprovado == "Texto confirmado pelo administrador"
    assert not (raiz / "ata.wav").exists()


def test_falha_ao_apagar_audio_nao_perde_referencia(trabalho, monkeypatch):
    sessoes, _, ata_id, raiz = trabalho
    with sessoes() as db:
        ata = db.get(models.Ata, ata_id)
        ata.estado = models.EstadoAta.aprovada
        ata.texto_aprovado = "Texto aprovado"
        db.commit()

    def falhar_unlink(_caminho, **_kwargs):
        raise OSError("volume indisponível")

    with monkeypatch.context() as patch:
        patch.setattr(Path, "unlink", falhar_unlink)
        assert limpar_audios_aprovados(sessoes, raiz) == 0

    with sessoes() as db:
        assert db.get(models.Ata, ata_id).audio_path == "ata.wav"
    assert (raiz / "ata.wav").exists()
    assert limpar_audios_aprovados(sessoes, raiz) == 1


def test_arranque_recupera_job_interrompido(trabalho):
    sessoes, job_id, _, _ = trabalho
    assert reservar_job(sessoes) == job_id
    assert recuperar_jobs(sessoes) == 1
    assert reservar_job(sessoes) == job_id
    with sessoes() as db:
        assert db.get(models.Job, job_id).tentativas == 2


def test_decisoes_exigem_excerto_literal():
    dados = {"resumo": "Reparação", "decisoes": [
        {"texto": "Reparar a entrada", "excerto": "Decidiram reparar a entrada",
         "por_confirmar": True},
    ], "pontos_por_confirmar": ["Montante"]}
    texto = _formatar_rascunho(dados, "Decidiram reparar a entrada hoje.")
    assert "por confirmar" in texto
    assert "Excerto: «Decidiram reparar a entrada»" in texto
    dados["decisoes"][0]["excerto"] = "Decidiram aprovar 5000 euros"
    with pytest.raises(FalhaProvider, match="excerto_sem_suporte"):
        _formatar_rascunho(dados, "Decidiram reparar a entrada hoje.")
