# DomusCast

Aplicação de gestão de condomínio para prédios autogeridos.  
Stack: Flutter (Android) - FastAPI - PostgreSQL - Docker

---

## Pré-requisitos

| Ferramenta | Versão mínima | Para quê |
|---|---|---|
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | 24+ | Correr API + base de dados |
| [Flutter SDK](https://docs.flutter.dev/get-started/install/windows/mobile) | 3.47+ | Compilar e correr a app Android |
| [Android Studio](https://developer.android.com/studio) | Qualquer | Emulador Android (AVD) |
| Python 3.11+ | -- | Só para correr os testes da API localmente (opcional) |

> **Nota:** o Docker Desktop tem de estar a correr antes de qualquer comando `docker compose`.

---

## Setup inicial (fazer uma vez)



### 1 - Scaffolding Android (só quem ainda não o fez)

```powershell
cd DomusCast\mobile
flutter create . --platforms android --org com.condoapp
flutter pub get
```

> Este comando gera os ficheiros nativos Android (`android/`) sem sobrescrever o código Dart existente.

### 2 - Criar o emulador Android (Android Studio)

1. Abre o Android Studio
2. **More Actions -> Virtual Device Manager -> +**
3. Escolher um telemóvel 
4. Clica ▶ para iniciar o emulador

---

## Correr o projeto

### Backend (API + base de dados)

```powershell
cd DomusCast
docker compose up --build
```

Aguarda a mensagem `Uvicorn running on http://0.0.0.0:8000`.  
A base de dados é criada e as migrações correm automaticamente.

O compose arranca quatro containers, os três últimos com a mesma imagem da API:

| Container | Para quê |
|---|---|
| `postgres` | Base de dados (porta 5433 no PC) |
| `api` | API em http://localhost:8000; corre as migrações ao arrancar |
| `worker-calendario` | US-28: publica as reuniões no calendário externo (job `publicar_calendario`); healthcheck em `/health`, porta 8082 interna |
| `calendario` | Simulador do serviço de calendário externo ([8.6](../docs/sprintA/sprintA.md#86-integração-externa)), em http://localhost:8001 |

#### Calendário externo: provocar falhas (US-28)

O simulador começa no modo `ok`. Cada modo é uma das condições de falha de 8.6:

```powershell
# indisponivel (503), lento (responde depois de atraso_ms; o Worker desiste aos 10 s),
# incompleto (200 sem id), invalido (200 com datas mal formadas), limite (429 com Retry-After: 30), ok
Invoke-RestMethod -Method Post http://localhost:8001/_chaos -ContentType 'application/json' -Body '{"modo":"indisponivel"}'
Invoke-RestMethod http://localhost:8001/_chaos                                   # modo atual
Invoke-RestMethod http://localhost:8001/calendars/condominio<id>/events          # eventos publicados
docker logs domuscast-worker-calendario-1                                        # tentativas e falhas (JSON)
```

Cada falha conta como uma tentativa. O Worker volta a tentar ao fim de 1, 2, 4 e 8 minutos (com `429`, espera pelo menos o `Retry-After`); à 5.ª falha a reunião fica `alternativo`. Para uma demonstração em segundos, arranca com `$env:WORKER_BACKOFF_UNIDADE_S = "1"; docker compose up --build`. Na VM, o simulador não tem porta publicada: `docker compose -f docker-compose.prod.yml exec calendario python -c "import httpx; print(httpx.post('http://localhost:8001/_chaos', json={'modo': 'indisponivel'}).json())"`.

| Endpoint | Descrição |
|---|---|
| `GET  /health` | Estado da API e da base de dados |
| `POST /reportes` | Criar reporte com `mostrar_nome` (falso por omissão); requer credencial de residente |
| `GET  /reportes` | Listar reportes conforme o papel; residentes nunca recebem fração e só recebem nome se `mostrar_nome=true`; `meu` indica os reportes do próprio |
| `POST /condominios` | Criar condomínio e frações (devolve a credencial do administrador) |
| `GET  /condominios/{id}/fracoes` | Listar frações (administrador) |
| `POST /fracoes/{id}/qr` | Gerar QR code de uma fração (administrador) |
| `GET  /fracoes/{id}/qr` | Listar os QR codes ativos de uma fração, sem o token (administrador) |
| `POST /fracoes/{id}/qr/revogar` | Revogar todos os QR codes ativos de uma fração (administrador) |
| `POST /qr/{id}/revogar` | Revogar um QR code (administrador) |
| `POST /identidades` | Residente entra com o token do QR code e o nome (devolve a credencial do dispositivo) |
| `GET  /fracoes/{id}/identidades` | Listar os residentes ativos de uma fração (administrador) |
| `DELETE /identidades/{id}` | Remover a identidade de um residente (administrador) |
| `GET  /docs` | Documentação interativa (Swagger UI) |

### App Flutter

Com o emulador aberto e o backend a correr:

```powershell
cd DomusCast\mobile
flutter run
```

> A app aponta para `http://10.0.2.2:8000` (endereço especial do emulador que aponta para `localhost` do PC).

Também podes correr a app pelo Android Studio: abre a pasta `DomusCast\mobile`, seleciona o emulador na barra de dispositivos e clica em **Run** (▶). A primeira configuração precisa de confirmar o Flutter SDK em **Settings > Languages & Frameworks > Flutter**.

---

## Testar no emulador

### 1. Arrancar tudo

1. Backend: `cd DomusCast; docker compose up --build` (deixa esta janela aberta).
2. Emulador: Android Studio > **Device Manager** > ▶ no telemóvel criado no setup.
3. App: noutra janela, `cd DomusCast\mobile; flutter run`.

### 2. Criar dados de teste (Swagger)

Abre http://localhost:8000/docs no browser. Em cada pedido: **Try it out**, preencher, **Execute**.

1. `POST /condominios`: cria o condomínio. Copia o `credencial_admin` da resposta.
2. Botão **Authorize** (no topo): cola a credencial e confirma. A partir daqui, os pedidos vão como administrador.
3. `POST /fracoes/{fracao_id}/qr`: usa um `id` das frações da resposta do passo 1. Devolve o `token` e o `link` do QR code.
4. `POST /identidades` com `{"token": "...", "nome": "..."}`: cria um residente nessa fração. A `credencial` da resposta serve para testar pedidos como residente (no **Authorize**).

Limite: 5 condomínios novos por hora no mesmo PC. Para mais QR codes, repete só o passo 3.

### 3. Comandos úteis

Corre no PowerShell, com o emulador ligado.

**O que é o `adb`:** Android Debug Bridge (`adb`) é o comando que liga o terminal ao emulador. Permite abrir links, limpar a sessão da app, simular internet em baixo e tirar screenshots. A pasta do SDK já está no Android Studio:
`%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`.

O comando é longo no PowerShell; define uma variável uma vez em cada terminal:

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb devices
```

`& $adb devices` deve mostrar `emulator-5554 device`. A variável `$adb` só vale nessa janela do PowerShell.

| Para quê | Comando |
|---|---|
| Abrir um link da app (ex.: o `link` do QR code) | `& $adb shell am start -a android.intent.action.VIEW -d "domuscast://entrar?t=<token>"` |
| Voltar ao primeiro acesso (apaga as sessões da app) | `& $adb shell pm clear com.condoapp.condoapp` |
| Simular "sem internet" (para voltar, `disable`) | `& $adb shell cmd connectivity airplane-mode enable` |
| Tirar uma screenshot para as evidências | `& $adb shell screencap -p /sdcard/ecra.png` e depois `& $adb pull /sdcard/ecra.png <ficheiro>.png` |
| Ver a base de dados | `docker exec -it domuscast-postgres-1 psql -U condoapp -d condoapp` |

As screenshots vão para `docs/sprintB/screenshots/us-nn/`, com os nomes `01-<ecra>.png`, `02-<ecra>.png` pela ordem do wireframe. Não uses `adb exec-out screencap ... > ficheiro`, porque no PowerShell a imagem fica corrompida.

### 4. Câmara e leitor de ecrã

- **Ler um QR code real:** a câmara do emulador mostra uma sala virtual. Para usar a webcam do PC, arranca o emulador por comando: `emulator -list-avds` mostra o nome, e depois `emulator -avd <nome> -camera-back webcam0` (os dois estão em `%LOCALAPPDATA%\Android\Sdk\emulator`). Mostra o QR code à webcam, inteiro e a 20 a 30 cm (por exemplo, uma fotografia no telemóvel).
- **TalkBack** (leitor de ecrã do Android, já vem no emulador):
  1. Para ouvi-lo em português, muda primeiro a língua do emulador:
     `& $adb shell am start -a android.settings.LOCALE_SETTINGS`
     Em **Settings > System > Languages**, escolhe **Add a language > Português (Portugal)** e arrasta-o para o topo.
  2. Ligar pelo comando:
     `& $adb shell settings put secure enabled_accessibility_services com.google.android.marvin.talkback/com.google.android.marvin.talkback.TalkBackService`
     Ou: em Settings > Accessibility > TalkBack, ativa o interruptor.
  3. Desligar:
     `& $adb shell settings delete secure enabled_accessibility_services`
     Ou: em Settings > Accessibility > TalkBack, desliga o interruptor.
  4. Com o TalkBack ligado, usa o rato na janela do emulador: arrastar para a direita passa ao elemento seguinte e duplo clique ativa. No Android Studio, o terminal não precisa de ser usado.

---
## Testes

### API (sem Docker, usa SQLite)

```powershell
cd DomusCast\api
pip install -r requirements-dev.txt
pytest tests/ -v
```

### Flutter

```powershell
cd DomusCast\mobile
flutter test
flutter analyze
```

---

## CI/CD

A pipeline corre automaticamente em cada push e PR para `main`.  
Ficheiro: `.github/workflows/ci.yml`

| Job | O que faz |
|---|---|
| `api` | `ruff check` (lint + segurança, ver `api/ruff.toml`) + `pip-audit` (SCA Python) + `pytest tests/` |
| `mobile` | `flutter analyze` + `flutter test` |
| `sast` | `semgrep` (regras `p/python` e `p/dockerfile`) |
| `sca-dart` | `osv-scanner` sobre `pubspec.lock` (SCA Dart) |
| `secrets` | `gitleaks` (deteta credenciais commitadas) |

A pipeline usa permissões mínimas (`contents: read`), actions fixadas ao SHA do commit e o Dependabot (`.github/dependabot.yml`) propõe atualizações semanais. A imagem da API corre como utilizador não-root, sem o `pip` (só é preciso no build), e o PostgreSQL só escuta em `127.0.0.1`.

### Verificações nos PRs para a `main`

Cada merge na `main` cria uma versão e faz o deploy, por isso os PRs para a `main` passam ainda por dois workflows. Devem estar marcados como obrigatórios nas regras de proteção da `main` (Settings > Branches).

| Workflow | Job | O que faz |
|---|---|---|
| `pr-regras.yml` | `regras` | Branch `feature/`, `feat/`, `bugfix/`, `fix/`, `docs/`, `chore/`, `ci/` ou `release/`; título do PR e commits no formato `[#<issue>] - <descrição>` ou `<Área>: <descrição>` (GitHub, Docker, Deploy, CI, Docs, Mobile, API). Regras em `.github/scripts/pr-rules.sh`, testadas em `tests.sh` e usadas também pelo hook `.githooks/commit-msg`. Não corre nos PRs do Dependabot |
| `pr-producao.yml` | `postgres` | Migrações em PostgreSQL (`upgrade`, `downgrade` e `upgrade`) e `pytest` contra PostgreSQL (`TEST_DATABASE_URL`) |
| | `docker` | `docker compose up --build`, `/health` com a base de dados ligada e Trivy na imagem da API (falha em HIGH ou CRITICAL com correção) |
| | `deploy` | `docker compose config` do `deploy/docker-compose.prod.yml` e `caddy validate` do `Caddyfile`, com a versão do Caddy da VM |
| | `apk` | `flutter build apk --release`, o mesmo comando do release |

Num PR que só muda `docs/` (ex.: a daily), o job `alteracoes` usa `.github/scripts/docs-only.sh` e os jobs de `pr-producao.yml` são ignorados, porque esse merge não cria versão nem deploy. Um job ignorado conta como aprovado nas verificações obrigatórias.

Para correr os testes da API contra PostgreSQL localmente (com a base de dados `ci_testes` criada):

```powershell
$env:TEST_DATABASE_URL = "postgresql://condoapp:condoapp@localhost:5433/ci_testes"
pytest tests/ -v
```

---

## Estrutura do projeto

```
DomusCast/
  api/
    app/
      main.py           ← FastAPI + /health
      models.py         ← Reporte (SQLAlchemy ORM)
      schemas.py        ← ReporteCreate / ReporteOut (Pydantic)
      routers/
        reportes.py     ← POST e GET /reportes
    alembic/            ← Migrações de base de dados
    tests/              ← 4 testes automatizados
    Dockerfile
    .dockerignore        ← Exclui .env, testes e ficheiros de desenvolvimento da imagem
    requirements.txt    ← Dependências de produção (imagem Docker)
    requirements-dev.txt ← + pytest, ruff, pip-audit (testes, lint e segurança)
    ruff.toml            ← Regras de lint e segurança (bandit)
  mobile/
    lib/
      main.dart                    ← Entrada da app
      theme.dart                   ← Tema centralizado (azul #0F3478)
      screens/
        landing_screen.dart        ← Ecrã inicial com animação
        reportes_list_screen.dart  ← Lista de reportes
        novo_reporte_screen.dart   ← Formulário de criação
      services/
        api_service.dart           ← Chamadas HTTP à API
      local/
        queue_db.dart              ← Fila offline (SQLite)
    test/
      widget_test.dart             ← Smoke test
    assets/icon/icon.png           ← Ícone da app
  landing/
    index.html                     ← Landing page web
  docker-compose.yml
docs/                              ← Documentação do projeto (Sprint A, backlog, etc.)
```

---

## Funcionalidades implementadas

### App móvel

| Funcionalidade | Detalhe |
|---|---|
| **Landing screen** | Ecrã inicial com gradiente azul, animação fade+slide, 3 features e botão "Entrar" |
| **Lista de reportes** | Cards com badge de estado colorido (Aberto / Em curso / Resolvido), data de criação e pull-to-refresh |
| **Criar reporte** | Formulário com validação, contador de caracteres e aviso de privacidade |
| **Modo offline** | Sem internet, o reporte é guardado localmente (SQLite) e enviado automaticamente quando a ligação voltar |
| **Idempotência** | Cada reporte tem uma chave aleatória única, reenvios não criam duplicados |
| **Estado de erro** | Ecrã de "Sem ligação" com botão de retry |
| **Estado vazio** | Mensagem de empty state quando não há reportes |

### API

| Funcionalidade | Detalhe |
|---|---|
| `POST /reportes` | US-02/US-09: cria reporte; campo `mostrar_nome` controla a visibilidade do nome; idempotente via `idempotency_key`; campos de contacto são recusados |
| `GET /reportes` | US-09: lista os reportes do condomínio conforme o papel; residente não recebe fração, recebe o nome só se o autor o mostrar e `meu` nos seus reportes; requer credencial (401) |
| `POST /condominios` | US-01: cria condomínio, frações (A, B, C…) e primeiro administrador; 1 a 200 frações, 5 criações por hora por IP (429) |
| `GET /condominios/{id}/fracoes` | US-01: frações e nº de residentes; requer `Authorization: Bearer <credencial>` do administrador; 401 sem credencial, 403 residente ou condomínio de outro administrador |
| `POST /fracoes/{id}/qr` | US-01: gera um token novo (só o hash fica guardado) e devolve-o uma vez com o link `domuscast://entrar?t=`; os anteriores continuam válidos; 401 sem credencial, 403 residente, 404 fração inexistente ou de outro condomínio |
| `GET /fracoes/{id}/qr` | US-20: QR codes ativos com `{id, criado_em, n_residentes}` (residentes que entraram com cada um e ainda têm acesso); 401 sem credencial, 403 residente, 404 fração inexistente ou de outro condomínio |
| `POST /fracoes/{id}/qr/revogar` | US-20: revoga todos os QR codes ativos da fração e devolve `{revogados}` (0 se não havia); as identidades já criadas não são afetadas |
| `POST /qr/{id}/revogar` | US-20: revoga um QR code e devolve `{revogados: 1}`; 404 se já foi revogado, não existe ou é de outro condomínio. Os dois `revogar` guardam o administrador em `qr_token.revogado_por` (migração `0006`) |
| `POST /identidades` | US-15: `{token, nome}` cria a identidade do residente e devolve `{id, nome, fracao, credencial}`; nome único por fração (ignora maiúsculas, acentos e espaços), máximo de 10 por fração, 30 tentativas por hora por QR code; erros 404 e 409 no formato `{codigo, mensagem, request_id}` |
| `GET /fracoes/{id}/identidades` | US-23: residentes ativos `{id, nome, criado_em}`; 401 sem credencial, 403 residente, 404 fração inexistente ou de outro condomínio |
| `DELETE /identidades/{id}` | US-23: apaga o nome, preenche `removida_em` e `removida_por` (migração `0007`) e devolve 204; a credencial removida recebe 401 e os reportes ficam como "Residente removido" (o administrador recebe `autor_removido` e a fração); 404 se já foi removida ou é de outro condomínio |
| `GET /health` | Verifica ligação à BD; devolve `{"status":"ok","db":"ok"}` ou 503 em modo degradado |
| Worker do calendário (`python -m app.worker.calendario`) | US-28: consome o job `publicar_calendario` criado por `POST /reunioes` e publica a reunião no simulador com o id `domuscast<reuniao_id>` (repetir não duplica o evento: `409` conta como já publicado); timeout de 10 s, 5 tentativas com esperas de 1, 2, 4 e 8 min, `Retry-After` respeitado; `estado_sync` passa a `sincronizada` ou, à 5.ª falha, a `alternativo` |
| `GET /reunioes?desde=` | US-28: devolve as reuniões criadas ou alteradas desde essa data (`reuniao.atualizado_em`, migração `0008`), para a app ver a mudança de `estado_sync` |
| Migrações Alembic | `0001_initial` - cria tabela `reporte` + enum `estado_reporte` no PostgreSQL |
| Swagger UI | Documentação interativa automática em `/docs` |

---

## Onde a IA entra (Sprint B, ainda não implementado)

A IA faz uma só coisa: transformar a gravação de uma assembleia num **rascunho de ata** que o administrador revê e aprova. São dois passos de IA diferentes, porque resolvem problemas diferentes, ambos feitos pelo Worker com a **API da OpenAI** (uma só chave):

| Passo | Modelo | O que faz |
|---|---|---|
| 1. Transcrever o áudio | `gpt-transcribe` | Converte a fala em texto corrido, palavra a palavra: longo, com hesitações e conversas laterais. Ainda não é uma ata |
| 2. Redigir o rascunho | `gpt-4o-mini` | Lê esse texto e escreve uma ata curta e formal: presentes, decisões e tarefas |

- Custo estimado: cerca de US$ 0,27 por ata de 1 hora de áudio (preços consultados a 2026-10-23; detalhe em [docs/sprintA/sprintA.md, secção 7.4](../docs/sprintA/sprintA.md#74-abordagem-de-avaliação)).
- O áudio da assembleia é enviado à OpenAI; por isso usamos gravações sintéticas nos testes e avisamos os presentes antes de gravar.
- A IA não publica nem decide nada: o rascunho fica "gerado por IA, pendente de revisão" até o administrador o aprovar. Sem IA, o administrador escreve a ata à mão.
- Detalhe e justificação: [docs/sprintA/sprintA.md, secção 7](../docs/sprintA/sprintA.md#7-responsible-ai-opportunity-assessment).

---

## O que vem a seguir (Sprint B)

- Autenticação real por QR code por fração (US-01, US-15)
- Gestão de estado dos reportes pelo administrador (US-03, US-05, US-22)
- Transcrição de atas por IA com fallback manual (US-10, US-24, US-25), ver [Onde a IA entra](#onde-a-ia-entra-sprint-b-ainda-não-implementado)
- Integração com calendário de assembleias (US-13, US-28, US-29)
- Workflow assíncrono com Worker + PostgreSQL queue (SKIP LOCKED)
- Testes de integração com PostgreSQL real na CI
