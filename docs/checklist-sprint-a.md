# Análise do Sprint A — O que está feito, incompleto e por fazer

> Referência principal: **LABDSOF-26-27-Assignment cap. 7.1** (Sprint 1 deliverables)
> Data da análise: 2026-10-15; ponto 6 atualizado em 2026-10-22.

---

## 1. Quadro-resumo (Sprint 1 deliverables vs. docs)

| # | Entregável (Assignment §7.1.2) | Estado | Localização |
|---|---|---|---|
| 1 | Problem and Opportunity Report | ✅ | [sprintA/sprintA.md §1](sprintA/sprintA.md#1-relatório-de-problema-e-oportunidade) |
| 2 | Market and Competitor Analysis | ⚠️ | [sprintA/sprintA.md §2](sprintA/sprintA.md#2-análise-de-mercado-e-concorrência) |
| 3 | User Research | ⚠️ | [sprintA/sprintA.md §3](sprintA/sprintA.md#3-investigação-de-utilizadores) |
| 4 | Product Vision | ✅ | [sprintA/sprintA.md §5](sprintA/sprintA.md#5-product-vision) |
| 5 | Product Backlog | ⚠️ | [backlog.md](backlog.md) |
| 6 | Responsible AI Opportunity Assessment | ✅ | [sprintA/sprintA.md §7](sprintA/sprintA.md#7-responsible-ai-opportunity-assessment) |
| 7 | Technical Design | ✅ | [sprintA/sprintA.md §8](sprintA/sprintA.md#8-technical-design) |
| 8 | Architecture Decision Records | ✅ | [sprintA/sprintA.md §9](sprintA/sprintA.md#9-architecture-decision-records) |
| 9 | Security and Privacy Assessment | ✅ | [sprintA/sprintA.md §10](sprintA/sprintA.md#10-security-and-privacy-assessment) |
| 10 | Walking Skeleton | ✅ | [sprintA/sprintA.md §11](sprintA/sprintA.md#11-walking-skeleton) — `DomusCast/` |

---

## 2. Detalhes por entregável

### ✅ Feito (substancialmente completo)

#### Product Vision — [§5](sprintA/sprintA.md#5-product-vision)
- [x] Personas (4 personas: Administrador, Condómino Ocupado, Inquilino Recente, Sénior Pouco Digital)
- [x] Value proposition (geral + por persona)
- [x] Principal user journeys (6 workflows com diagramas de atividade)
- [x] Success criteria (9 critérios mensuráveis)
- [x] MVP definition → [backlog.md §3](backlog.md#3-mvp)

#### Product Backlog — [backlog.md](backlog.md)
- [x] 17 user stories + 1 NFR priorizadas com MoSCoW
- [x] Critérios de aceitação por história
- [x] Sprint objectives → [§6.1](sprintA/sprintA.md#61-objetivos-dos-sprints)
- [x] Initial release plan (Sprint A/B/C) → [backlog.md §2](backlog.md#2-plano-de-release-inicial-visão-multi-sprint)
- [x] Sprint B Backlog separado → [sprintB/backlog.md](sprintB/backlog.md)

#### Security and Privacy Assessment — [§10](sprintA/sprintA.md#10-security-and-privacy-assessment)
- [x] Dados sensíveis identificados (§10.1)
- [x] Controlo de acessos (§10.2)
- [x] Minimização e finalidade / RGPD (§10.3)
- [x] Retenção (§10.4)
- [x] QR code, revogação e abuso (§10.5)
- [x] Modelo de ameaças inicial (§10.6)

#### Itens transversais do assignment (§0)
- [x] Metodologia / Work methodology → [§0](sprintA/sprintA.md#0-processo-e-metodologia-de-equipa)
- [x] Definition of Ready → [§0](sprintA/sprintA.md#definition-of-ready-dor)
- [x] Definition of Done → [§0](sprintA/sprintA.md#definition-of-done-dod)
- [x] Papéis da equipa / People and responsibilities → [§0](sprintA/sprintA.md#papéis-da-equipa)
- [x] NFRs → [requisitos.md](requisitos.md#requisitos-não-funcionais)
- [x] Assumptions & Dependencies → [§1](sprintA/sprintA.md#pressupostos-e-riscos)

---

### ⚠️ Itens com conteúdo ou validação pendente

#### 1 — Problem and Opportunity Report — [§1](sprintA/sprintA.md#1-relatório-de-problema-e-oportunidade)

| Sub-item | Estado | Nota |
|---|---|---|
| Target community | ✅ | Presente |
| Problem statement | ✅ | Presente |
| Stakeholder map | ✅ | Presente |
| Problem evidence | ✅ | 3 posts de fóruns Reddit (r/TudoCasa, r/tudoCondominio) com padrão identificado e limitações documentadas |
| Assumptions and risks | ✅ | Presente |

> Resultados do questionário Google Forms ainda pendentes. Quando disponíveis, atualizar a secção de evidência com dados primários.

---

#### 2 — Market and Competitor Analysis — [§2](sprintA/sprintA.md#2-análise-de-mercado-e-concorrência)

| Sub-item | Estado | Nota |
|---|---|---|
| Relevant alternatives | ✅ | 7 alternativas analisadas |
| Strengths and weaknesses | ✅ | Presente na tabela |
| Opportunity for differentiation | ✅ | §2.2 + §2.3 |
| **Dados/fontes concretas** | ⚠️ | `TODO` no topo do §2 — números de utilizadores, datas e dados de lojas de apps por validar |

**O que falta:** substituir o `TODO` de fontes concretas por referências verificadas (links, datas de acesso, ratings reais).

---

#### 3 — User Research — [§3](sprintA/sprintA.md#3-investigação-de-utilizadores)

| Sub-item | Estado | Nota |
|---|---|---|
| Research method | ✅ | Questionário + reviews de apps + observação informal |
| **Findings** | ❌ | "A aguardar resultados do inquérito" |
| **Limitations** | ❌ | "A aguardar resultados do inquérito" |
| **Resulting product decisions** | ❌ | "A aguardar resultados do inquérito" |

**O que falta:** publicar (ou resumir) os resultados do inquérito; documentar as limitações da metodologia (amostra de conveniência, ausência de utilizadores reais); ligar conclusões às decisões de produto já tomadas.

> ⚠️ O assignment (§5.3) proíbe explicitamente fabricar evidências de user research — se não houver resultados do inquérito, a secção deve reconhecer isso honestamente como limitação e apoiar-se nas outras duas fontes (reviews + observação).

---

#### 6 — Responsible AI Opportunity Assessment — [§7](sprintA/sprintA.md#7-responsible-ai-opportunity-assessment)

| Sub-item | Estado | Nota |
|---|---|---|
| Proposed AI-assisted workflow | ✅ | Transcrição + rascunho de ata (§7.1) |
| Expected value | ✅ | §7.2 |
| Risks | ✅ | §7.3 |
| Evaluation approach | ✅ | §7.4 define conjunto sintético, métricas, metas propostas, latência e estimativa de custo; §7.1 propõe os modelos locais. Os valores serão medidos no Sprint B/C. |
| Baseline and fallback | ✅ | §7.5 |

**O que falta executar:** implementar a proposta local no Sprint B e medir qualidade, latência, recursos e custo na máquina de demonstração no Sprint B/C. As metas de §7.4 ainda não são resultados.

---

#### Operating costs estimation

O custo da IA está estimado em [§7.4](sprintA/sprintA.md#74-abordagem-de-avaliação), com pressupostos explícitos e medição futura. Continua a faltar uma estimativa dos custos operacionais globais do produto, se a equipa decidir incluí-la.

---

### ✅ Feito (adicionado após criação da checklist)

#### 7 — Technical Design — [§8](sprintA/sprintA.md#8-technical-design)

| Sub-item | Estado | Nota |
|---|---|---|
| System context | ✅ | §8.1 — tabela de atores/sistemas externos; diagrama em `technical-design.drawio` |
| Container/component view | ✅ | §8.2 — App Flutter, API FastAPI, Worker, PostgreSQL, Simulador Calendário |
| Data model | ✅ | §8.3 — 13 entidades com campos, relações e notas de retenção |
| API outline | ✅ | §8.4 — tabela completa de endpoints com método, rota e US associada |
| Asynchronous workflow | ✅ | §8.5 — retries com backoff, idempotência, SKIP LOCKED, consistência eventual |
| External integration | ✅ | §8.6 — 3 níveis de degradação (simulador → iCal → dados locais) |
| Deployment view | ✅ | §8.8 — containers, CI/CD, rollback, APK |
| **Observabilidade** | ✅ | §8.7 — logs JSON, health checks, métricas Prometheus, Grafana, SLIs |
| **TODO pendente** | ⚠️ | Exportar diagramas do `technical-design.drawio` para PNG (`td-01` a `td-05`); decidir ambiente de deploy (VM ou máquina da equipa) |

#### 8 — Architecture Decision Records — [§9](sprintA/sprintA.md#9-architecture-decision-records)

9 ADRs formalizados, todos em Draft até revisão com os docentes:
- ADR-001: QR code partilhado + nome autodeclarado
- ADR-002: Flutter demonstrado em Android
- ADR-003: Backend Python / FastAPI
- ADR-004: API + Worker como dois containers com BD partilhada
- ADR-005: PostgreSQL como única BD e fila de jobs
- ADR-006: Fila local SQLite offline-first
- ADR-007: Calendário por simulador + feed iCal
- ADR-008: Autenticação de administrador mock no MVP
- ADR-009: Notificações locais sem fornecedor de push

---

### ✅ Feito (adicionado após criação da checklist)

#### 10 — Walking Skeleton — [§11](sprintA/sprintA.md#11-walking-skeleton)

| Sub-item | Estado | Localização |
|---|---|---|
| Minimal end-to-end implementation | ✅ | Flutter → `POST /reportes` → PostgreSQL → `GET /reportes` → lista na app |
| Source repository | ✅ | Repositório Git existe; código em `DomusCast/` |
| Automated build | ✅ | `.github/workflows/ci.yml` (jobs `api` + `mobile`) |
| Initial test | ✅ | 4 testes API (`test_reportes.py`) + 2 widget tests (`widget_test.dart`); todos a passar |
| Containerized deployment | ✅ | `DomusCast/docker-compose.yml` + `DomusCast/api/Dockerfile` |

**Notas de setup para Android:**
- O `mobile/` já inclui o scaffolding Android (`android/`, `applicationId` `com.condoapp.condoapp`); só é preciso correr `flutter pub get`. Quem precisar de o regenerar usa `flutter create . --platforms android --org com.condoapp`.
- A CI valida `flutter analyze` + `flutter test` sem necessitar de scaffolding Android.

---

## 3. Itens da lista original do enunciado vs. docs

| Item | Estado | Onde |
|---|---|---|
| Product vision | ✅ | [sprintA.md §5](sprintA/sprintA.md#5-product-vision) |
| User personas | ✅ | [sprintA.md §5.1](sprintA/sprintA.md#51-personas) |
| Customer journeys / General user workflow | ✅ | [sprintA.md §5.3](sprintA/sprintA.md#53-user-journey) + [imagens](sprintA/images/) |
| Domain model | ✅ | [sprintA.md §8.3](sprintA/sprintA.md#83-modelo-de-dados) — 13 entidades com campos e relações |
| Architecture & Technology | ✅ | [sprintA.md §8](sprintA/sprintA.md#8-technical-design) + [§9](sprintA/sprintA.md#9-architecture-decision-records) — stack definida (Flutter, FastAPI, PostgreSQL) + 9 ADRs |
| Assumptions & Dependencies | ✅ | [sprintA.md §1](sprintA/sprintA.md#pressupostos-e-riscos) |
| Operating costs estimation | ⚠️ | Custo da IA estimado em [sprintA.md §7.4](sprintA/sprintA.md#74-abordagem-de-avaliação); custos globais do produto ainda sem estimativa |
| Prioritized Product Backlog (epics) | ✅ | [backlog.md](backlog.md) |
| NFRs | ✅ | [requisitos.md](requisitos.md#requisitos-não-funcionais) |
| High-level scope of Sprint 1 | ✅ | [backlog.md §2](backlog.md#2-plano-de-release-inicial-visão-multi-sprint) |
| Team presentation | ⚠️ | [sprintA.md §0](sprintA/sprintA.md#papéis-da-equipa) tem papéis mas **sem nomes de pessoas** |
| People and responsibilities | ⚠️ | Idem — papéis definidos, pessoas não identificadas |
| Work methodology | ✅ | [sprintA.md §0](sprintA/sprintA.md#0-processo-e-metodologia-de-equipa) |
| Definition of Ready | ✅ | [sprintA.md §0](sprintA/sprintA.md#definition-of-ready-dor) |
| Definition of Done | ✅ | [sprintA.md §0](sprintA/sprintA.md#definition-of-done-dod) |

---

## 4. Itens adicionais do assignment não cobertos nos docs

### Ethical Engagement Design (assignment §5.5)
O US-16 (indicador de progresso) é o mecanismo de engagement, mas não existe secção a responder às 5 perguntas obrigatórias:
1. Que comportamento o mecanismo incentiva?
2. Por que isso beneficia o utilizador/comunidade?
3. Como se previne manipulação/abuso?
4. Pode excluir, expor ou desencorajar utilizadores?
5. Como pode o utilizador controlar ou desativar o mecanismo?

Os critérios de aceitação do US-16 tocam parcialmente nestes pontos mas não os endereçam explicitamente como secção de produto.

### Investor Engagement (assignment §5.7)
O assignment exige que **pelo menos uma decisão de produto ou técnica seja revisada em resposta ao feedback dos docentes (investidores)**, e que a alteração e o seu racional sejam documentados. Não existe nenhuma secção a registar este histórico de feedback.

---

## 5. Pendente de validação com os docentes (investidores)

> Colocar ao professor na próxima sprint review. Registar a resposta e atualizar o estado das histórias afetadas em [backlog.md](backlog.md) para **In Review** → **Approved**.

- [ ] **MVP**: O professor concorda que as histórias "Must have" (US-01, 02, 03, 04, 05, 09, 15 + NFR-01) são o experimento mínimo credível? Há algo essencial em falta, ou algo Must have que deva descer de prioridade?
- [ ] **Prioridades MoSCoW**: As histórias "Should have" (US-06, 07, 08, 10, 13, 14) e "Could have" (US-11, 12, 16, 17) estão corretamente posicionadas na perspetiva do cliente?
- [ ] **Plano de release**: A distribuição Sprint B (fatia vertical) / Sprint C (robustez e avaliação) faz sentido ou há histórias que devam mudar de sprint?
- [ ] **Won't have**: O professor concorda com o que foi excluído (quotas, gestão financeira, votações, multi-prédio)?

