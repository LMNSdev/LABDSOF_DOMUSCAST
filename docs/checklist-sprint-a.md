# Análise do Sprint A — O que está feito, incompleto e por fazer

> Referência principal: **LABDSOF-26-27-Assignment cap. 7.1** (Sprint 1 deliverables)
> Data da análise: 2026-10-15

---

## 1. Quadro-resumo (Sprint 1 deliverables vs. docs)

| # | Entregável (Assignment §7.1.2) | Estado | Localização |
|---|---|---|---|
| 1 | Problem and Opportunity Report | ✅ | [sprintA/sprintA.md §1](sprintA/sprintA.md#1-relatório-de-problema-e-oportunidade) |
| 2 | Market and Competitor Analysis | ⚠️ | [sprintA/sprintA.md §2](sprintA/sprintA.md#2-análise-de-mercado-e-concorrência) |
| 3 | User Research | ⚠️ | [sprintA/sprintA.md §3](sprintA/sprintA.md#3-investigação-de-utilizadores) |
| 4 | Product Vision | ✅ | [sprintA/sprintA.md §5](sprintA/sprintA.md#5-product-vision) |
| 5 | Product Backlog | ⚠️ | [backlog.md](backlog.md) |
| 6 | Responsible AI Opportunity Assessment | ⚠️ | [sprintA/sprintA.md §7](sprintA/sprintA.md#7-responsible-ai-opportunity-assessment) |
| 7 | Technical Design | ❌ | [sprintA/sprintA.md §8](sprintA/sprintA.md#8-technical-design) — vazio |
| 8 | Architecture Decision Records | ❌ | [sprintA/sprintA.md §9](sprintA/sprintA.md#9-architecture-decision-records) — vazio |
| 9 | Security and Privacy Assessment | ✅ | [sprintA/sprintA.md §10](sprintA/sprintA.md#10-security-and-privacy-assessment) |
| 10 | Walking Skeleton | ❌ | [sprintA/sprintA.md §11](sprintA/sprintA.md#11-walking-skeleton) — vazio |

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

### ⚠️ Incompleto (estrutura existe, falta conteúdo obrigatório)

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
| Evaluation approach | ⚠️ | Estrutura presente (§7.4) mas faltam: critérios de aceitação (`TODO`), latência máxima aceitável (`TODO`), custo por hora de áudio (`TODO`), modelo/serviço escolhido (`TODO`) |
| Baseline and fallback | ✅ | §7.5 |

**O que falta em §7.4:**
- Escolher o serviço/modelo de transcrição (ex.: Whisper, Google STT)
- Definir critério de aceitação quantitativo (ex.: ≥ 80% das decisões captadas, ≤ 5% de informação inventada)
- Definir latência máxima aceitável
- Definir custo estimado por hora de áudio

---

#### Operating costs estimation

Não existe como secção própria nos docs. Mencionado parcialmente como `TODO` no §7.4 (custo por hora de áudio). O assignment não exige uma secção dedicada de custos operacionais no Sprint 1, mas o tema está incompleto para o AI assessment.

---

### ❌ Em falta (vazio ou por criar)

#### 7 — Technical Design — [§8](sprintA/sprintA.md#8-technical-design) — **completamente vazio**

O assignment §7.1.2 exige:

| Sub-item | O que criar |
|---|---|
| System context | Diagrama C4 nível 1: a app, os utilizadores e os sistemas externos |
| Container/component view | Diagrama C4 nível 2: frontend, backend(s), DB, serviço de IA, calendário externo |
| Data model | Entidades principais e relações (Condomínio, Fração, Identidade, Reporte, Aviso, Assembleia, HistóricoEstado) |
| API outline | Endpoints principais com método, rota, request/response resumido |
| Asynchronous workflow | Diagrama ou descrição do workflow de processamento de áudio (retries, deduplicação, eventual consistency) |
| External integration | Como se integra o Google Calendar / alternativa; como se integra o serviço de transcrição |
| Deployment view | Diagrama de deployment (containers Docker, onde corre cada componente) |

---

#### 8 — Architecture Decision Records — [§9](sprintA/sprintA.md#9-architecture-decision-records) — **completamente vazio**

Existe apenas um ADR mencionado em texto (ADR-001: nome autodeclarado não verificado) mas nunca foi formalizado. O assignment exige:

- Escolhas arquiteturais e tecnológicas principais (linguagem, framework, BD, serviço de IA, calendário)
- Alternativas consideradas
- Racional da decisão
- Consequências e trade-offs

Pelo menos 3-5 ADRs são esperados:
- ADR-001: Identificação por nome autodeclarado (mencionado mas não formalizado)
- ADR-002: Escolha de stack tecnológico (frontend/backend)
- ADR-003: Escolha de base de dados
- ADR-004: Serviço de transcrição de áudio por IA
- ADR-005: Estratégia de autenticação (mock no MVP)

---

#### 10 — Walking Skeleton — [§11](sprintA/sprintA.md#11-walking-skeleton) — **completamente vazio**

O assignment exige:

| Sub-item | O que criar |
|---|---|
| Minimal end-to-end implementation | Código funcional ponta-a-ponta mínimo (ex.: residente cria reporte → admin vê na lista) |
| Source repository | ✅ Repositório Git existe |
| Automated build | Pipeline de CI que compila/empacota o projeto |
| Initial test | Pelo menos um teste automatizado a passar na CI |
| Containerized deployment | `Dockerfile` (ou `docker-compose`) que sobe a app localmente |

---

## 3. Itens da lista original do enunciado vs. docs

| Item | Estado | Onde |
|---|---|---|
| Product vision | ✅ | [sprintA.md §5](sprintA/sprintA.md#5-product-vision) |
| User personas | ✅ | [sprintA.md §5.1](sprintA/sprintA.md#51-personas) |
| Customer journeys / General user workflow | ✅ | [sprintA.md §5.3](sprintA/sprintA.md#53-user-journey) + [imagens](sprintA/images/) |
| Domain model | ❌ | Faz parte do Technical Design (§8) — **não existe** |
| Architecture & Technology | ❌ | Technical Design (§8) + ADR (§9) — **ambos vazios** |
| Assumptions & Dependencies | ✅ | [sprintA.md §1](sprintA/sprintA.md#pressupostos-e-riscos) |
| Operating costs estimation | ⚠️ | Só mencionado como TODO no §7.4 (custo por hora de áudio) |
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

