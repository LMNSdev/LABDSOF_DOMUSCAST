# Rubric and evidence guide

Scale: **0** Not delivered, **1** Very basic, **2** Partially complete, **3** Almost complete (lacks justifications), **4** Well-defined with justifications.

"Where to look" lists the usual location in this repo (`S` = `docs/sprintA/sprintA.md`). Confirm the content is really there; sections move.

## 1. Product vision

- **4:** well-defined vision with clear justifications. **3:** nearly complete, lacks some justifications. **2:** vague or unclear. **1:** basic, minimal detail. **0:** none.
- **Sub-criteria:** clarity (clear, concise); target audience and their specific needs; value proposition (benefit to users); feasibility (technical and financial constraints); stakeholder alignment.
- **Where to look:** S §5.6, §5.2, §2.3, §1 (stakeholders), §0 investor feedback.
- **Level-4 test:** a vision statement that fits in a few sentences; names who and what need; states the measurable benefit; each constraint (tech, cost) is addressed with a pointer to §8/§8.10; stakeholder feedback is traceable to a decision.

## 2. User personas

- **4:** comprehensive personas with detailed attributes, needs and clear justifications. **3:** detailed but lacking thorough justifications. **2:** basic, no detailed characteristics. **1:** minimal, generic. **0:** none.
- **Sub-criteria:** detail (characteristics, attributes); needs, goals and challenges; representativeness of the real audience.
- **Where to look:** S §5.1, §1 stakeholder map and evidence, §3 (research behind them; missing results limit the "representative of the real audience" sub-criterion only).
- **Level-4 test:** each persona has role, context, goals, pain points, tech/accessibility profile; each is tied to evidence (§1 evidence, §3 findings) and to at least one user story; the set covers every actor in the backlog (resident, administrator, committee member, accessibility needs...).

## 3. General workflow

- **4:** all steps clearly defined and justified. **3:** nearly complete, lacks justifications. **2:** some missing or unclear steps. **1:** basic steps, minimal detail. **0:** none.
- **Sub-criteria:** clarity; completeness (all major steps and activities); alignment with personas' journeys, needs and goals.
- **Where to look:** S §5.3 User Journey, `workflows.drawio`, S §8.5, images in `docs/sprintA/images/`.
- **Level-4 test:** one journey per primary persona; happy path plus failure/degraded/offline branches; every step maps to a user story; diagrams and text agree.

## 4. Domain model

- **4:** complete, detailed, with clear entities, relationships and justifications. **3:** nearly complete, lacks detailed justifications. **2:** some entities or relationships missing or unclear. **1:** basic, minimal entities and relationships. **0:** none.
- **Sub-criteria:** entities and relationships; attributes detailed; consistency with workflow and user needs.
- **Where to look:** S §8.3 Modelo de dados, S §4, ER/class diagram image.
- **Level-4 test:** every noun used in stories and workflows is an entity or attribute; cardinalities and keys given; privacy-relevant attributes marked; justifications for modelling choices (for example why a separate identity entity). If only a physical data model exists, check that a domain-level view (entities and relationships in business terms) is also clear.

## 5. Architecture & technology

- **4:** detailed architecture with clear technology choices and justification for each. **3:** detailed, minor gaps. **2:** general architecture, some key technologies or patterns missing. **1:** basic outline with significant gaps. **0:** none.
- **Sub-criteria:** technology selection appropriate to the needs; clear architectural documentation.
- **Where to look:** S §8.1 context, §8.2 containers, §8.8 deployment, §8.6 integration, §8.7 observability, §9 ADRs, `technical-design.drawio`, S §11.
- **Level-4 test:** context, container and deployment views exist and agree; each technology (Flutter, FastAPI, PostgreSQL, OpenAI, Docker, CI) has an ADR with context, decision, alternatives considered, rationale and consequences/trade-offs; ADRs are forward-looking; component boundaries, data ownership, sync/async communication and failure handling are explained; diagrams are readable in the rendered document.

## 6. Assumptions & dependencies

- **4:** all critical assumptions and dependencies clearly identified and justified. **3:** most identified, not thoroughly justified. **2:** some identified, lacking clarity or completeness. **1:** minimal, lacking detail. **0:** none.
- **Sub-criteria:** identification of key assumptions and dependencies; risk management (plan to manage or mitigate).
- **Where to look:** S §1 "Pressupostos e riscos", S §5.4, S §7.3, S §10.6, ADRs consequences.
- **Level-4 test:** assumptions and dependencies (people, tools, external services, licences, hardware, access to users, docentes) are listed separately; each has an owner or impact, a mitigation or fallback, and a risk rating (probability x impact); external dependencies (OpenAI, calendar, Android toolchain, GitHub) appear here and in the architecture.

## 7. Operating costs estimation

- **4:** detailed estimation with clear breakdown and justification for each item. **3:** nearly complete, lacks thorough justifications. **2:** basic, no detailed breakdown or justification. **1:** very basic, minimal breakdown. **0:** none.
- **Sub-criteria:** completeness (all anticipated costs included and detailed); accuracy (realistic, based on accurate data).
- **Where to look:** S §8.10.
- **Level-4 test:** every cost line has unit price, quantity/assumption, monthly and yearly total, source and date of the price; covers infrastructure (VM, storage, backup, domain), AI usage, third-party licences (for example store fees), people/time if relevant, and at least two usage scenarios appropriate to the product (for example one building versus many; count the scenarios that actually exist before saying they are missing). Arithmetic is correct and figures match the chosen technologies in §9. Prices verified against official pages.

## 8. Prioritized product backlog (epics)

- **4:** well-prioritized backlog with detailed epics and clear justifications. **3:** nearly complete and prioritized, lacking detailed justifications. **2:** items present, lacking prioritization or details. **1:** basic list, no prioritization. **0:** none.
- **Sub-criteria:** clarity of items; prioritization by importance and impact; alignment with vision and goals.
- **Where to look:** `docs/backlog.md`, S §4, S §6, `docs/requisitos.md`.
- **Level-4 test:** epics/features exist above stories (the course asks for epics); every story is "Como ... quero ... para ..."; MoSCoW priority with a written justification (value, risk, dependency), prioritized with the customer/docentes (state how, without fabricating); points in agreed scale; stories trace to vision, personas and requirements; release plan consistent with Sprint B/C scope.

## 9. NFRs

- **4:** detailed NFRs with clear specifications and justification. **3:** almost complete with detailed specifications, lacking thorough justifications. **2:** some NFRs without detailed specification or justification. **1:** minimal, no detail or specificity. **0:** none.
- **Sub-criteria:** specification (clearly defined); coverage (performance, security, usability, etc.).
- **Where to look:** `docs/requisitos.md`, S §4, S §8.7, S §10.
- **Level-4 test:** each NFR is measurable (metric, threshold, how verified); categories covered: performance, security, privacy/RGPD, usability, accessibility, availability/resilience, offline, maintainability, observability, portability, cost; each NFR has a rationale and traces to an ADR, story or test.

## 10. High-level scope of Sprint 1

- **4:** detailed scope with clear deliverables and justifications; **acceptance criteria for each US properly defined**. **3:** nearly complete, lacking justifications. **2:** basic scope, unclear deliverables or justifications. **1:** basic, minimal detail on deliverables. **0:** none.
- **Sub-criteria:** clarity of objectives and deliverables; acceptance criteria for each US; feasibility within the sprint; review plan for evaluating the outcome.
- **Where to look:** S §6.1, §6.2, `docs/sprintB/backlog.md`, `docs/backlog.md` (release plan), S §11 (walking skeleton).
- **Level-4 test:** sprint objective stated; selected stories each have testable acceptance criteria; capacity versus points justifies feasibility; the Sprint B backlog respects the Definition of Ready with **no `TBC` cells**; points agree with the product backlog; a sprint review/evaluation plan exists (who, when, what is demonstrated, how success is judged). Note the ambiguity "Sprint 1": cover the Sprint A deliverables and the next sprint's scope.

## 11. Team presentation

- No rubric row. **Pass** only if `docs/sprintA/presentation/*.pptx` exists and, using the checker's full slide text and coverage table: every topic is covered (vision, personas, workflow, domain model, architecture and technology, assumptions and dependencies, costs, prioritized backlog (epics), NFRs, scope of the next sprint, methodology, DoR, DoD); no slide marks a required artefact as unfinished ("Por iniciar", "Em curso", TBC); and no slide contradicts the written documents (product name, integrations, features in or out of the MVP, component names). Otherwise **Fail**, listing each missing topic and each contradiction with the slide number and the document line it conflicts with.
- Check the deck date against the latest changes to the documents; a deck older than the documents it summarises is probably stale.

## 12. Work methodology

- **4:** comprehensive methodology with clear practices, principles and justifications. **3:** nearly complete, lacking justifications. **2:** basic, missing some practices or principles. **1:** very basic, significant omissions. **0:** none.
- **Sub-criteria:** clarity; suitability; adaptability to change; plan to evaluate and refine the methodology.
- **Where to look:** S §0 (Metodologia, GitHub Flow, issues, board, roles), `.github/` PR templates, `.githooks/`.
- **Level-4 test:** Scrum events with cadence and who attends (planning, daily, review, retrospective); sprint length; artefacts; roles with responsibilities; why Scrum and GitHub Flow suit a five-person student team; how change is handled (backlog refinement, re-prioritization after investor feedback, with the documented example); how the process is evaluated (retrospective, metrics, actions) and refined.

## 13. Definition of Ready

- **4:** comprehensive, clear criteria and justifications. **3:** nearly complete, lacking justifications. **2:** basic, missing key criteria. **1:** basic, significant omissions. **0:** none.
- **Sub-criteria:** clear criteria; aligned with objectives and stakeholders; communicated and understood by the team; feasible; periodic review plan.
- **Where to look:** S §0 DoR, `docs/sprintB/backlog.md` (DoR columns), `.github/PULL_REQUEST_TEMPLATE/`.
- **Level-4 test:** criteria are a verifiable checklist; each criterion says why it exists; the DoR matches the columns used in the Sprint backlog (labels agree, for example no criterion named "Diagrama de Sequência" that describes something else); how and when it is reviewed (retrospective) is stated; the team has actually applied it (DoR checked for each Sprint B story).

## 14. Definition of Done

- Same level pattern as DoR.
- **Sub-criteria:** clear criteria; aligned with objectives and quality standards; communicated; **verifiable and measurable**; periodic review plan.
- **Where to look:** S §0 DoD, `.github/workflows/ci.yml`, PR templates, S §11 CI/CD.
- **Level-4 test:** each criterion is objectively checkable (CI green, PR approved by at least one reviewer, coverage or test type, docs updated); the criteria match what the pipeline and PR templates really enforce; justification per criterion; review plan.
