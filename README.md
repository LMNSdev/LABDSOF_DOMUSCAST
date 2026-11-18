# DomusCast

Aplicação móvel de gestão de condomínio para prédios autogeridos em Portugal. Substitui o grupo de WhatsApp e os posters no hall por reportes de avarias com estado, dono e histórico auditável, com privacidade por desenho, e leva avisos, reuniões e atas de assembleia a todos os residentes.

- **Utilizadores:** residentes (proprietários e inquilinos), que se identificam pelo QR code da fração e pelo nome, e o administrador do condomínio.
- **MVP:** onboarding por QR code, ciclo completo de um reporte (criar, consultar, triar, resolver), privacidade do autor, ata assistida por IA com fallback manual, calendário externo simulado e modo degradado. Detalhe em [Sprint A, 5.6](docs/sprintA/sprintA.md#56-visão-do-produto-benefício-esperado-e-fronteira-do-mvp).

## Stack

Flutter (Android) - FastAPI (Python) - PostgreSQL - Docker. As decisões de arquitetura estão nas [ADRs](docs/sprintA/sprintA.md#9-architecture-decision-records).

## Estrutura do repositório

| Pasta | Conteúdo |
|---|---|
| [`DomusCast/api`](DomusCast/api) | API em FastAPI, migrações Alembic e testes |
| [`DomusCast/mobile`](DomusCast/mobile) | App Flutter (Android) |
| [`DomusCast/landing`](DomusCast/landing) | Landing page |
| [`docs`](docs) | Documentação do produto e dos sprints |
| [`.github`](.github) | CI, Dependabot e templates de pull request |

## Correr o projeto

As instruções de setup (Docker, Flutter, emulador Android), arranque da API e testes estão no [README da aplicação](DomusCast/README.md). Resumo:

```powershell
cd DomusCast
docker compose up --build   # API em http://localhost:8000 e base de dados
```

## Documentação

### Produto
- [Product Backlog](docs/backlog.md): lista priorizada de user stories (MoSCoW e story points)
- [Requisitos](docs/requisitos.md): requisitos funcionais e não funcionais e o estado de validação

### Sprints
- [Sprint A: Descoberta, Validação e Design](docs/sprintA/sprintA.md): problema, mercado, investigação de utilizadores, visão, IA responsável, desenho técnico, segurança e walking skeleton
- [Sprint B](docs/sprintB/sprintB.md): [Sprint Backlog](docs/sprintB/backlog.md) e [requisitos](docs/sprintB/requisitos.md)
- [Sprint C](docs/sprintC/sprintC.md)

### Uso de IA
Como a equipa usou IA (agentes, skills e prompts, criação e revisão de conteúdo, e como contestámos os resultados): [docs/use-of-ai.md](docs/use-of-ai.md).

## Processo

Scrum com um sprint por fase do enunciado e GitHub Flow: a `main` está sempre estável e as alterações entram por pull request revisto, usando os [templates](.github/PULL_REQUEST_TEMPLATE) de feature, bugfix e release. A [CI](.github/workflows/ci.yml) corre o lint, os testes e as verificações de segurança da API e da app em cada push e pull request. Como cada merge na `main` cria uma versão e faz o deploy, os pull requests para a `main` passam ainda por [regras de branch, título e commits](.github/workflows/pr-regras.yml) e por [verificações de produção](.github/workflows/pr-producao.yml): migrações e testes em PostgreSQL, arranque da imagem Docker com análise de vulnerabilidades (Trivy) e build do APK ([detalhe](DomusCast/README.md#cicd)). Metodologia, papéis, Definition of Ready e Definition of Done: [Sprint A, capítulo 0](docs/sprintA/sprintA.md#0-processo-e-metodologia-de-equipa).
