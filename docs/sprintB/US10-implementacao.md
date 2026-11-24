# US-10 — Implementação e validação

Issue [#88](https://github.com/LMNSdev/LABDSOF_DOMUSCAST/issues/88). A implementação segue o [Product Backlog](../backlog.md), o [refinamento do Sprint B](refinamento.md#us-10-transcrição-de-ata-por-ia), o [Technical Design](../sprintA/sprintA.md#71-fluxo-assistido-por-ia) e o [wireframe](design/us-10.html).

## Percurso

1. O administrador abre uma reunião, incluindo reuniões passadas, e vê o aviso de transferência do áudio e da transcrição à OpenAI antes de escolher o ficheiro.
2. `POST /reunioes/{id}/ata/audio` valida a reunião, o formato e o tamanho, grava o original no volume partilhado e cria a ata e um job na mesma transação. Responde `202` com `a_transcrever`. Um reenvio do mesmo ficheiro reutiliza a ata e o job; após uma falha, repõe o job como pendente.
3. O Worker reserva jobs `transcrever` por `FOR UPDATE SKIP LOCKED`, normaliza o áudio com FFmpeg, chama `gpt-transcribe` e usa `gpt-4o-mini` para propor a ata. O rascunho exige excertos literais da transcrição para as decisões e marca incerteza como «por confirmar». O áudio nunca é enviado para o modelo de redação.
4. `GET /reunioes/{id}/ata` mostra estado e resultado apenas ao administrador do condomínio. A app atualiza o estado a cada 15 segundos enquanto processa. O original pode ser obtido por `GET /reunioes/{id}/ata/audio`, também restrito ao administrador e sem cache.
5. Após cinco tentativas sem sucesso, o estado é `falhou_transcricao` e o original continua guardado. Uma resposta tardia do Worker não altera uma ata já aprovada ou manual. Quando a US-24 gravar o estado `aprovada`, deve manter `audio_path` até o Worker eliminar o original e os dados intermédios. A limpeza é retomada depois de uma interrupção.

## Decisões de implementação

| Tema | Valor implementado | Estado documental |
|---|---|---|
| Formatos e tamanho total | MP3, M4A e WAV; 200 MB | A confirmar pela equipa, conforme o refinamento |
| Duração | Até 60 minutos | Meta de avaliação do Technical Design; o original é preservado se exceder |
| Partes enviadas à OpenAI | Até 25 MB por pedido | Limite da integração externa |
| Tentativas | 5 no total, com esperas de 1, 2, 4 e 8 minutos | O refinamento também enumera 16 minutos: esse quinto intervalo só caberia entre seis tentativas. Confirmar com a equipa |
| Chave da OpenAI | `OPENAI_API_KEY` só no Worker | Definir em `DomusCast/.env` no desenvolvimento ou `/opt/domuscast/.env` na VM; nunca versionar |

O processamento não cria uma fila offline para áudio no dispositivo: a US-18 trata a fila local. O ato de aprovar e publicar é da US-24; a US-10 mantém o original até esse passo e prepara a limpeza após o estado aprovado. A ata manual em falha é da US-25. Estas dependências foram mantidas para não publicar texto gerado pela IA sem revisão humana.

## Validação realizada

- `pytest tests/ -q`: 151 testes passaram, incluindo autorização, condomínio alheio, 413/415/422/503, idempotência, falha, cinco tentativas, proteção de ata aprovada, limpeza retomável, consulta privada do original e contrato HTTP com a OpenAI simulado.
- `ruff check .`: passou.
- `flutter test`: 132 testes passaram, incluindo upload multipart, aviso de privacidade, estados, falhas, reuniões passadas e semântica de acessibilidade.
- Alembic em PostgreSQL real: `upgrade head`, `downgrade base`, `upgrade head` passaram em base isolada.
- Docker Compose: API e Worker arrancaram com health checks saudáveis; FFmpeg transcodificou áudio WAV sintético.

Os testes do Provider usam respostas simuladas e áudio sintético. Uma transcrição real com chave OpenAI e a avaliação de qualidade das gravações sintéticas de 10–15 e 60 minutos previstas em [7.4](../sprintA/sprintA.md#74-abordagem-de-avaliação) ainda dependem de uma chave e da amostra da equipa.
