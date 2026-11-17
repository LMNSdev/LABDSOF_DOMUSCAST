---
name: us-implementation
description: "Use when implementing a DomusCast user story (US-nn) end to end: checking it is ready, creating the branch, writing the Alembic migration, models, schemas, FastAPI router and pytest tests, the Flutter screens, API service and widget tests, running the same checks as CI, writing the evidence page with screenshots and preparing the commits and the PR against the Definition of Done. Trigger words: implementar US, implement user story, começar US, US-15, US-02, endpoint, migração, ecrã Flutter, testes, evidências, us-nn.md, screenshots, PR da US, Definition of Done, DoD."
argument-hint: "The story to implement, e.g. US-15 (#79)"
---

# Implementing a user story (DomusCast)

Step-by-step guide: **what** to do, **how** to do it in this codebase and **when** each step happens. Every step has a gate; do not move on until the gate passes. Repository text stays in PT-PT (see `.github/copilot-instructions.md`).

**Git and GitHub are the user's job.** Never create or switch branches, stage, commit, push or open PRs yourself. At each point where one is needed, stop and give the exact commands (and the PR text) for the user to run, then continue when they confirm. Read-only git (`status`, `diff`, `log`) is fine.

## Phase 0: gate check (before touching code)

Read the story's row in `docs/sprintB/backlog.md`, its criteria in `docs/backlog.md`, its section in `docs/sprintB/refinamento.md` and its wireframe in `docs/sprintB/design/`.

**Stop and tell the user if any is true:**
- "DoR cumprida" is not `Sim (...)`: the story must go through refinement first (skill `us-workflow`).
- The contract leaves a response code, limit or field undefined: that is a refinement decision, not an implementation choice.
- A dependency the story needs is not merged (e.g. resident authentication comes from US-15).
- The story has no issue number, or it is assigned to someone else.

Then give the user the story's checklist to paste in the issue: one line per migration, endpoint, screen, test group and the evidence page.

## Phase 1: branch (user runs)

Give the user these commands and wait for confirmation before editing files:

```powershell
git switch main; git pull
git switch -c feature/<issue>-<descricao-curta>
```

## Phase 2: API (order matters: data, then contract, then behaviour, then tests)

1. **Migration** in `DomusCast/api/alembic/versions/`: next number (`0003_<descricao>.py`, `revision = "0003"`, `down_revision = "0002"`), with `upgrade()` and `downgrade()`. Mirror the change in `app/models.py`. Migrations run on container start (`entrypoint.sh`: `alembic upgrade head`).
2. **Schemas** in `app/schemas.py`: `XCreate` for input, `XOut` for output (`model_config = {"from_attributes": True}`), other responses named for what they are (`CondominioCriado`, `QrGerado`). Constraints with `Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=...)]` and `Field(ge=, le=)`. Inputs that must reject unknown fields: `model_config = {"extra": "forbid"}`; for multipart, receive the form as `Annotated[Model, Form()]`, because FastAPI ignores extra `Form` fields otherwise.
3. **Router** in `app/routers/<dominio>.py` (`router = APIRouter()`), registered in `app/main.py` with `prefix` and `tags`. Declare `response_model` and `status_code`. Docstring cites the US.
4. **Authorization** with dependencies from `app/security.py`: `admin_atual` + `exigir_admin_do_condominio(admin, condominio_id)` for admin routes. Tokens: `gerar_token()` and store only `hash_token(token)`. Residents get their credential from `POST /identidades` (US-15), but there is **no `residente_atual` dependency yet**: the first resident route (US-02) creates it next to `admin_atual`, looking up `Identidade.credencial_hash` and returning 401 when `removida_em` is set (US-23 relies on that).
5. **Limits:** `rate_limit.verificar(request, "<chave>", MAXIMO, JANELA_S)` counts per IP by default. Pass `por_ip=False` when the refined contract counts per token or per fração (US-15: `f"identidade_qr:{qr.id}"`, because neighbours share the building's public IP). Test it with a second client on another IP: `TestClient(app, client=("10.0.0.2", 50000))`.
6. **Errors:** use exactly the codes in the story's contract. When the contract has a `codigo`, raise `ErroApi(status, "<codigo>", "<mensagem PT-PT>")` from `app/erros.py`; the handler in `main.py` returns `{codigo, mensagem, request_id}`. Never invent another channel for the code (an `X-Codigo` header was rejected in the US-15 review).
7. **Tests** in `DomusCast/api/tests/test_<dominio>.py`, using the `client` and `db` fixtures from `conftest.py` (SQLite file, not PostgreSQL: avoid PostgreSQL-only behaviour or test it in Docker). One test per acceptance criterion and per success/failure case in "Validação planeada". Names in Portuguese describing the rule: `test_nome_repetido_na_fracao_devolve_409`. Reset rate limits between tests with a fixture calling `rate_limit.reset()`.

**Gate:** `cd DomusCast/api; pytest tests/ -v; ruff check .` both clean.

## Phase 3: app

1. **API calls** in `lib/services/api_service.dart`: one method per endpoint, `_auth(credencial)` for the Bearer header, return through `_corpo(r, esperado)`. On an unexpected status it throws `ApiException(statusCode, codigo)`, with `codigo` read from the error body when present; screens switch on `(e.statusCode, e.codigo)`. Network failures are `http.ClientException` or `SocketException`: catch only those for "sem internet", never a bare `catch (e)`. Keep the `client` constructor parameter so tests can inject a `MockClient`.
2. **Local storage** of credentials only through `flutter_secure_storage`, behind an abstract store with an in-memory implementation for tests (patterns: `lib/services/sessao_admin.dart`, `lib/services/sessao_residente.dart`). Store only the fields a screen uses. `LandingScreen` takes both stores (`store`, `storeResidente`) and a `links` stream, so tests inject them; never create a secure store inside a screen without a constructor parameter.
   - Native plugins (camera, links) do not exist in `flutter test`: give the screen a parameter to replace them (`LerQrScreen(camara: SizedBox())`, `LandingScreen(links: controller.stream)`), and create `AppLinks()` only in `main()`.
3. **Screens** in `lib/screens/<nome>_screen.dart`, one per wireframe screen or state. Match the wireframe: same texts, same states (loading, empty, error, offline). Use `theme.dart`; do not hardcode new colours. Navigation follows `docs/sprintB/navegacao.md` (tabs by role in `HomeScreen`).
4. **Accessibility:** every button, field and image has a label readable by a screen reader (`Semantics`, `tooltip`, `semanticLabel`).
5. **Tests** in `test/<us>_test.dart` with `testWidgets`, `MockClient` and the helpers used in `test/us01_admin_test.dart`: one per screen state and per user-visible failure (each error code shows the right message).

**Gate:** `cd DomusCast/mobile; flutter analyze; flutter test` both clean (on this machine: `scripts\flutter.ps1`, see Phase 4).

### Mistakes found in the US-15 review (do not repeat)

- Editing files while on `main`. Check `git branch --show-current` before the first edit.
- Building a screen the wireframe does not have (a text field to paste the token instead of the camera) or changing approved texts (the wireframe says the name is seen by the administrator; "ninguém vê" was wrong). The wireframe and the refinement are the spec.
- Overengineering: a second `HomeScreen` constructor "for compatibility", a relationship nothing uses, session fields no screen reads, `from_attributes` on a response built by hand. If nothing uses it, remove it.
- Tests that cannot compile or pass: `const` objects containing `DateTime(...)`; `find.text` with part of a sentence (it matches the exact text only); the same message shown twice (in `errorText` and in a box) with `findsOneWidget`; a test store created but never injected.
- Reporting tests as passing without running them. If a gate cannot run, say so and leave the result as `[A PREENCHER]`.

## Phase 4: end-to-end check (same as CI)

CI (`.github/workflows/ci.yml`) runs: `ruff check .`, `pip-audit -r requirements.txt`, `pytest tests/ -v`, `flutter analyze`, `flutter test`, Semgrep (fails on any finding), OSV scan of `pubspec.lock`, Gitleaks. Then run the full path by hand:

```powershell
cd DomusCast; docker compose up --build
```

and walk through every wireframe screen in the Android emulator against the API, success and failure. Any difference from the wireframe is either fixed or recorded for team approval.

**Fast path on this machine (Windows, ISEP).** Do not search the disk for Flutter and do not install it: AppLocker blocks a downloaded `dart.exe` ("Acesso negado") and `flutter.bat` then retries forever without showing the error. Use the scripts in [scripts/](./scripts/), already tested; total time about 15 minutes (most of it the first APK build).

1. **Check the tools (1 command):** `docker info --format '{{.ServerVersion}}'` (if it fails, ask the user to open Docker Desktop) and `& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -list-avds`.
2. **API checks:** `py -m venv <pasta fora do repo>`, `<pasta>\Scripts\python -m pip install -r DomusCast\api\requirements-dev.txt`, then in `DomusCast\api`: `<pasta>\Scripts\python -m pytest tests/ -q -p no:cacheprovider` and `<pasta>\Scripts\python -m ruff check --no-cache .` (`python` is the Microsoft Store alias; use `py`).
3. **App checks** (same Flutter version as CI, in Docker): `powershell -ExecutionPolicy Bypass -File .github\skills\us-implementation\scripts\flutter.ps1`. It runs `pub get`, `analyze` and `test`; the first run creates the image `domuscast-flutter:<versão do CI>`. `flutter pub get` updates `pubspec.lock` when `pubspec.yaml` changed: that file goes in the commit.
4. **Run it:** start the API with `cd DomusCast; docker compose up --build -d` (check `curl.exe -s http://localhost:8000/health`) and, at the same time, build the APK: `flutter.ps1 "flutter build apk --debug"` (about 10 minutes the first time, async).
5. **Demo data through the API**, not through the app: `Invoke-RestMethod -Method Post http://localhost:8000/condominios ...`, then `POST /fracoes/{id}/qr` with the admin credential to get tokens, and `POST /identidades` for residents that must already exist. States the API cannot create yet (e.g. a revoked QR code before US-20) go through `docker exec domuscast-postgres-1 psql -U condoapp -d condoapp -c "..."`; say so in the evidence page.
6. **Screenshots**, with the helper functions (list and usage at the top of the file):

```powershell
. .github\skills\us-implementation\scripts\emulador.ps1 -Us us-nn
Arrancar; Instalar; Limpar          # emulador ligado, APK instalado, app como no primeiro acesso
Textos                              # o que está no ecrã (textos, botões, campos)
Tocar "Entrar"; Shot "01-entrada"
Link $token; TocarCampo; Escrever "Rui Costa"; Enter; Shot "05-nome"
SemRede; ...; Shot "10-sem-internet"; ComRede
```

Before each `Shot`, check the screen with `Textos` (or open the PNG with the `view` tool): a screenshot of the wrong state is worse than none. Take every wireframe screen, success and failure, in its order. Only real captures; never generate or edit images. The camera in the emulator shows a virtual scene, so a real QR code cannot be read there: record it as not demonstrated.

**Pitfalls that cost time in US-15:**
- Windows PowerShell 5.1: no `head`/`tail` (use `Select-Object -First/-Last`); nested quotes in `bash -c` break (pass a script file); `$ErrorActionPreference = "Stop"` turns docker's stderr into a fatal error; `adb exec-out screencap -p > x.png` corrupts the PNG.
- `ghcr.io/cirruslabs/flutter:stable` can be older than CI. A different Flutter version changes `flutter analyze` (a newer one marks every `material.dart` import as deprecated), so always use `flutter.ps1`, which pins the CI version.
- The Android package is `com.condoapp.condoapp`, not `domuscast`.
- Keys 111 (Esc) and 4 (Back) close dialogs and screens; to submit a field use `Enter`.
- Keep the line endings of existing files (most are CRLF; scripts are UTF-8 with BOM so PowerShell 5.1 reads the accents); a file rewritten with LF shows up as fully changed in `git diff`.
- Leave the emulator and the containers running at the end, and tell the user how to stop them (`docker compose down`).
**Gate:** every acceptance criterion verified by a test or on the emulator.

## Phase 5: evidence page

Create `docs/sprintB/us-nn.md` from [the template](./templates/evidencias.md) (model: `docs/sprintB/us-01.md`). Screenshots in `docs/sprintB/screenshots/us-nn/`, named `01-<ecra>.png`, `02-<ecra>.png`, in the order of the wireframe. Record decisions taken during implementation and differences from the wireframe. Update other docs the story changes (Sprint Backlog row, `sprintA.md` §8.3/§8.4 when a table or endpoint was added, `DomusCast/README.md` when setup changed).

**Gitleaks reads the docs too.** Its `generic-api-key` rule flags a keyword (`API`, `token`, `key`, `secret`, `credential`, `auth`...) followed by `:`, `=` or `,` and a code-like value, e.g. "API: \`test_nome_vazio_devolve_422\`". In evidence tables write "pytest: \`test_...\`", never put real tokens or credentials in docs or screenshots, and check before giving the commit commands: `docker run --rm -v "${PWD}:/repo" zricethezav/gitleaks:v8.24.3 detect --source /repo --no-git --redact -v` (same version as CI). A false positive already pushed is fixed by correcting the text and listing its fingerprints (shown in the CI log) in `.gitleaksignore`, because the PR scan rereads every commit of the branch.

## Phase 6: commits and PR (user runs)

After each coherent piece of work (migration, endpoint with tests, screen with tests, evidence page), give the user the commands, listing only the story's files:

```powershell
git add <ficheiros da US>
git commit -m "[#<issue>] - <descrição>"
git push -u origin feature/<issue>-<descricao-curta>
```

At the end, give the user the PR title and the full PR body following `.github/PULL_REQUEST_TEMPLATE/feature.md` (they open it with `?template=feature.md` on the compare URL):
- `Closes #<issue>` only when every criterion is met.
- Acceptance criteria ticked, how to test, link to the evidence page, reviewer notes with decisions and risks.
- Remind them to ask for a reviewer; the QA (Leonardo Costa) verifies the criteria before merge.

**Gate (Definition of Done, `sprintA.md` chapter 0):** end to end implemented; UI matches the wireframe or differences approved; all criteria verified; tests added and CI green; PR approved by at least 1 person and merged; commits in format, no secrets or personal data; docs updated.

## Phase 7: after merge (user does it)

Remind the user to tick the criteria in the issue and remove "Blocked" from issues that depended on it; update the story in the Sprint Backlog (a file change, so it goes in a commit the user runs). The person mentions it in the next daily.

## Known gaps in the codebase (check before relying on them)

- **Error format:** `ErroApi` (`app/erros.py`, from US-15) gives `{codigo, mensagem, request_id}`, but only the routes that raise it use it. 422 (FastAPI validation), 429 (`rate_limit`) and the US-01 routes still return `{"detail": "..."}`. The `X-Request-ID` header is not implemented, and `request_id` is a new random value per error (not yet linked to logs).
- **Resident authentication:** the credential exists (US-15) but the `residente_atual` dependency does not; see Phase 2, step 4.
- **Structured JSON logs** (§8.7, RNF-05) are not configured.
- **Other condomínio:** §8.4 says 404 for resources of another condomínio; `exigir_admin_do_condominio` returns 403. Follow the story's refined contract and do not change the shared helper without the team.
- **Rate limit** is in memory (lost on restart, one API instance only); per IP by default, per key with `por_ip=False`.
- **Links and camera** (from US-15): `domuscast://entrar?t=<token>` is registered in `AndroidManifest.xml` and handled by `app_links`; QR reading uses `mobile_scanner` (`LerQrScreen`); `tokenDoLink` extracts the token.

When implementation reveals a new gap or a decision the contract did not cover, stop, explain it to the user and record the agreed decision in the evidence page.
