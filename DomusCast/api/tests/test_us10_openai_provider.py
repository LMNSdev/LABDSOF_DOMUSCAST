"""Contrato HTTP dos dois passos de IA, sem chamadas nem chaves reais."""

import json
from types import SimpleNamespace

import httpx
import pytest

from app.worker import openai_provider
from app.worker.openai_provider import FalhaProvider, OpenAIProvider


def test_provider_envia_audio_e_transcricao_aos_endpoints_certos(tmp_path, monkeypatch):
    parte = tmp_path / "parte.mp3"
    parte.write_bytes(b"audio-sintetico")
    monkeypatch.setattr(openai_provider, "_partes", lambda _caminho, _pasta: [parte])
    pedidos = []

    def responder(pedido: httpx.Request) -> httpx.Response:
        pedidos.append(pedido)
        assert pedido.headers["authorization"] == "Bearer chave-de-teste"
        if pedido.url.path == "/v1/audio/transcriptions":
            assert b'name="model"' in pedido.content
            assert b"gpt-transcribe" in pedido.content
            assert b'name="file"; filename="parte.mp3"' in pedido.content
            return httpx.Response(200, json={"text": "Decidiram reparar a entrada."})
        assert pedido.url.path == "/v1/responses"
        corpo = json.loads(pedido.content)
        assert corpo["model"] == "gpt-4o-mini"
        assert corpo["store"] is False
        assert corpo["text"]["format"]["type"] == "json_schema"
        assert corpo["text"]["format"]["strict"] is True
        assert "Decidiram reparar a entrada." in corpo["input"]
        return httpx.Response(200, json={
            "status": "completed",
            "output": [{"type": "message", "content": [{"type": "output_text", "text": json.dumps({
                "resumo": "Reparação da entrada",
                "decisoes": [{"texto": "Reparar a entrada", "excerto": "Decidiram reparar a entrada.",
                              "por_confirmar": True}],
                "pontos_por_confirmar": ["Orçamento"],
            })}]}],
        })

    with httpx.Client(base_url="https://api.openai.com/v1", transport=httpx.MockTransport(responder)) as cliente:
        provider = OpenAIProvider(chave="chave-de-teste", cliente=cliente)
        transcricao = provider.transcrever(parte)
        rascunho = provider.gerar_rascunho(transcricao)

    assert len(pedidos) == 2
    assert "Gerado por IA. Pendente de revisão." in rascunho
    assert "por confirmar" in rascunho
    assert "Excerto: «Decidiram reparar a entrada.»" in rascunho


def test_provider_rejeita_resposta_incompleta_sem_expor_conteudo(tmp_path, monkeypatch):
    parte = tmp_path / "parte.mp3"
    parte.write_bytes(b"audio-sintetico")
    monkeypatch.setattr(openai_provider, "_partes", lambda _caminho, _pasta: [parte])

    def responder(pedido: httpx.Request) -> httpx.Response:
        if pedido.url.path == "/v1/audio/transcriptions":
            return httpx.Response(200, json={"text": "Decidiram reparar a entrada."})
        return httpx.Response(200, json={"status": "incomplete", "output": []})

    with httpx.Client(base_url="https://api.openai.com/v1", transport=httpx.MockTransport(responder)) as cliente:
        provider = OpenAIProvider(chave="chave-de-teste", cliente=cliente)
        transcricao = provider.transcrever(parte)
        with pytest.raises(FalhaProvider, match="resposta_ia_incompleta"):
            provider.gerar_rascunho(transcricao)


def test_provider_sem_chave_nao_envia_audio(tmp_path, monkeypatch):
    parte = tmp_path / "parte.mp3"
    parte.write_bytes(b"audio-sintetico")
    monkeypatch.setattr(openai_provider, "_partes", lambda _caminho, _pasta: [parte])
    with httpx.Client(base_url="https://api.openai.com/v1",
                      transport=httpx.MockTransport(lambda _: pytest.fail("pedido inesperado"))) as cliente:
        provider = OpenAIProvider(chave="", cliente=cliente)
        with pytest.raises(FalhaProvider, match="chave_ia_ausente"):
            provider.transcrever(parte)


def test_provider_fecha_apenas_o_cliente_que_criou():
    provider = OpenAIProvider(chave="chave-de-teste")
    cliente = provider.cliente
    provider.close()
    assert cliente.is_closed

    externo = httpx.Client(transport=httpx.MockTransport(lambda _: httpx.Response(200)))
    provider = OpenAIProvider(chave="chave-de-teste", cliente=externo)
    provider.close()
    assert not externo.is_closed
    externo.close()


def test_assembleia_de_mais_de_uma_hora_cabe_no_limite(tmp_path, monkeypatch):
    monkeypatch.setattr(openai_provider, "_executavel", lambda _: "ffprobe")
    duracao = 70 * 60
    monkeypatch.setattr(openai_provider.subprocess, "run",
                        lambda *_args, **_kwargs: SimpleNamespace(stdout=str(duracao)))
    assert openai_provider._duracao(tmp_path / "audio.wav") == duracao

    duracao = 3 * 60 * 60 + 1
    with pytest.raises(FalhaProvider, match="duracao_audio_invalida"):
        openai_provider._duracao(tmp_path / "audio.wav")


def test_audio_longo_e_dividido_mesmo_abaixo_de_25_mb(tmp_path, monkeypatch):
    monkeypatch.setattr(openai_provider, "_duracao", lambda _: 70 * 60)
    monkeypatch.setattr(openai_provider, "_transcodificar",
                        lambda _origem, destino, _duracao: destino.write_bytes(b"audio-curto"))
    monkeypatch.setattr(openai_provider, "_executavel", lambda _: "ffmpeg")
    comandos = []

    def dividir(comando, **_kwargs):
        comandos.append(comando)
        openai_provider.Path(comando[-1]).write_bytes(b"parte")

    monkeypatch.setattr(openai_provider.subprocess, "run", dividir)
    partes = openai_provider._partes(tmp_path / "origem.wav", tmp_path)
    assert len(partes) == 5
    assert [int(comando[comando.index("-ss") + 1]) for comando in comandos] == [0, 900, 1800, 2700, 3600]
    assert all(parte.stat().st_size <= openai_provider.MAX_PARTE_BYTES for parte in partes)


def test_saldo_esgotado_e_identificado_sem_guardar_resposta(tmp_path, monkeypatch):
    parte = tmp_path / "parte.mp3"
    parte.write_bytes(b"audio-sintetico")
    monkeypatch.setattr(openai_provider, "_partes", lambda _caminho, _pasta: [parte])

    def responder(_pedido):
        return httpx.Response(429, json={"error": {
            "code": "credit_balance_exhausted", "type": "insufficient_quota",
        }})

    with httpx.Client(base_url="https://api.openai.com/v1",
                      transport=httpx.MockTransport(responder)) as cliente:
        provider = OpenAIProvider(chave="chave-de-teste", cliente=cliente)
        with pytest.raises(FalhaProvider, match="credito_ia_esgotado"):
            provider.transcrever(parte)


@pytest.mark.parametrize("campo,valor", [
    ("code", "credit_balance_exhausted"),
    ("code", "insufficient_quota"),
    ("type", "insufficient_quota"),
])
@pytest.mark.parametrize("etapa", ["transcricao", "rascunho"])
def test_quota_esgotada_e_definitiva_nas_duas_etapas(tmp_path, monkeypatch, campo, valor, etapa):
    parte = tmp_path / "parte.mp3"
    parte.write_bytes(b"audio-sintetico")
    monkeypatch.setattr(openai_provider, "_partes", lambda _caminho, _pasta: [parte])

    def responder(_pedido):
        return httpx.Response(429, json={"error": {campo: valor}})

    with httpx.Client(base_url="https://api.openai.com/v1",
                      transport=httpx.MockTransport(responder)) as cliente:
        provider = OpenAIProvider(chave="chave-de-teste", cliente=cliente)
        with pytest.raises(FalhaProvider, match="credito_ia_esgotado"):
            if etapa == "transcricao":
                provider.transcrever(parte)
            else:
                provider.gerar_rascunho("Texto sintético")
