"""Contrato HTTP dos dois passos de IA, sem chamadas nem chaves reais."""

import json

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
