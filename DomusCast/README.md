# DomusCast

Aplicação de gestão de condomínio para prédios autogeridos.  
Stack: Flutter (Android) · FastAPI · PostgreSQL · Docker

---

## Pré-requisitos

| Ferramenta | Versão mínima | Para quê |
|---|---|---|
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | 24+ | Correr API + base de dados |
| [Flutter SDK](https://docs.flutter.dev/get-started/install/windows/mobile) | 3.24+ | Compilar e correr a app Android |
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
2. **More Actions → Virtual Device Manager → +**
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

| Endpoint | Descrição |
|---|---|
| `GET  /health` | Estado da API e da base de dados |
| `POST /reportes` | Criar reporte |
| `GET  /reportes` | Listar reportes |
| `GET  /docs` | Documentação interativa (Swagger UI) |

### App Flutter

Com o emulador aberto e o backend a correr:

```powershell
cd DomusCast\mobile
flutter run
```

> A app aponta para `http://10.0.2.2:8000` (endereço especial do emulador que aponta para `localhost` do PC).

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

A pipeline usa permissões mínimas (`contents: read`), actions fixadas ao SHA do commit e o Dependabot (`.github/dependabot.yml`) propõe atualizações semanais. A imagem da API corre como utilizador não-root e o PostgreSQL só escuta em `127.0.0.1`.

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
    requirements-dev.txt ← + pytest, ruff, httpx, pip-audit (testes, lint e segurança)
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
| `POST /reportes` | Cria reporte; idempotente via `idempotency_key` |
| `GET /reportes` | Lista todos os reportes por ordem de criação descendente |
| `GET /health` | Verifica ligação à BD; devolve `{"status":"ok","db":"ok"}` ou 503 em modo degradado |
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
- Gestão de estado dos reportes pelo administrador (US-04, US-05, US-22)
- Transcrição de atas por IA com fallback manual (US-10, US-24, US-25), ver [Onde a IA entra](#onde-a-ia-entra-sprint-b-ainda-não-implementado)
- Integração com calendário de assembleias (US-13, US-28, US-29)
- Workflow assíncrono com Worker + PostgreSQL queue (SKIP LOCKED)
- Testes de integração com PostgreSQL real na CI
