# Assignment deliverables and cross-cutting requirements

Source: `LABDSOF-26-27-Assignment.pdf` (§5 common product requirements, §7.1.2 Sprint 1 deliverables, §7.1.3 investor review, §8 practices, §11 ethics). The M1 rubric grades the quality of the documents; this file checks that **every deliverable the assignment lists for Sprint 1 exists**. Mark each **Done / Partial / Missing** with file#section evidence. A missing deliverable is a finding even when no rubric row covers it, and it caps the rubric row named in the last column when that row's sub-criteria depend on it.

`S` = `docs/sprintA/sprintA.md`.

## Sprint 1 deliverables (PDF §7.1.2)

| # | Deliverable and required parts | Usual location | Feeds rubric row |
|---|---|---|---|
| 1 | **Problem and Opportunity Report**: target community, problem statement, stakeholder map, problem evidence, assumptions and risks | S §1 | Vision, Personas, Assumptions |
| 2 | **Market and Competitor Analysis**: relevant alternatives (digital and non-digital), strengths and weaknesses, opportunity for differentiation; PDF §5.2 also asks for target users, features, business model, UX, privacy and trust per alternative, ending in a value proposition | S §2 | Vision |
| 3 | **User Research**: method, findings, limitations, resulting product decisions. Limitations in access to real users must be documented; results must never be fabricated (PDF §5.3, §11) | S §3 | Personas |
| 4 | **Product Vision**: personas, value proposition, principal user journeys, success criteria, MVP definition; PDF §5.4 adds expected community benefit and product risks; success criteria must be measurable | S §5 | Vision, Personas, Workflow |
| 5 | **Product Backlog**: prioritized stories, acceptance criteria, sprint objectives, initial release plan | `docs/backlog.md`, S §6 | Backlog, Scope |
| 6 | **Responsible AI Opportunity Assessment**: proposed AI workflow, expected value, risks, evaluation approach, baseline or fallback | S §7 | Architecture |
| 7 | **Technical Design**: system context, container/component view, data model, API outline, asynchronous workflow, external integration, deployment view | S §8 | Architecture, Domain model |
| 8 | **Architecture Decision Records**: principal choices, alternatives considered, rationale, consequences and trade-offs | S §9 | Architecture |
| 9 | **Security and Privacy Assessment**: initial threat model, sensitive data, access-control requirements, data minimisation, retention | S §10 | NFRs, Architecture |
| 10 | **Walking Skeleton**: minimal end-to-end implementation, source repository, automated build, initial test, containerised deployment | S §11, `DomusCast/`, `.github/workflows/ci.yml`, `docker-compose.yml` | Definition of Done, Architecture |

Level-4 test for the AI assessment (6): the workflow solves a demonstrated need (not AI for its own sake); evaluation names intended purpose, representative inputs, adverse cases, expected outputs, acceptance criteria, quality measures, latency, cost and known limitations, and the origin and limits of the evaluation data; a non-AI baseline or fallback keeps the main workflow running; uncertain AI output is never presented as verified fact; prompt injection, fabricated output, disclosure of data, harmful content, bias, user correction and human approval for consequential actions are addressed (PDF §5.6.1 to §5.6.3).

Level-4 test for the technical design (7): the PDF asks the team to justify component boundaries, data ownership, sync and async communication, coupling and cohesion, deployment implications and failure handling (§6.2); the async workflow shows retries, duplicate events, failures and eventual consistency (§6.3); the data model covers lifecycle, retention, deletion, backup and privacy (§6.4); the external integration handles unavailable, delayed, incomplete and invalid data (§6.5); authentication and authorization are designed, a mocked MVP authentication is acceptable (§6.6); observability has structured logs, health checks, metrics, correlation ids, error reporting and a small dashboard (§6.7); at least one degraded-mode scenario is defined (§6.8). A single deployable is accepted only with convincing evidence and explicit, enforceable module boundaries; otherwise two independently deployable backend components are required.

## Cross-cutting requirements to verify

| Requirement (PDF) | What must be written down |
|---|---|
| §5.5 Ethical engagement | At least one participation mechanism with the five explanations: behaviour encouraged, benefit, misuse prevention, risk of excluding or exposing users, how to opt out. Points, badges and rankings need a link to the desired outcome |
| §5.7 Investor engagement | At least one product or technical decision revised after teaching-staff feedback, with the change and rationale documented and traceable (S §0 investor section) |
| §8.1 Version control | Meaningful commits, branching strategy, PRs, reviews, issue references, repository documentation. Commit counts are not evidence of contribution |
| §8.2 Agile management | Backlog, sprint planning, assignment, decisions, sprint goals, progress and stakeholder feedback recorded in Jira or an equivalent (GitHub Projects) with screenshots or links |
| §8.4, §8.5 Delivery | Containers, reproducible build, configuration per environment, secrets not in the repository, deployment instructions, rollback or recovery note, CI pipeline with build, tests, static analysis and dependency checks |
| §11 Ethics and conduct | No unjustified personal data; synthetic data where enough; research participants informed; research not fabricated; AI-generated content declared and reviewed; third-party code, datasets and tools acknowledged; security controls not weakened for demos |

## Investor review question (PDF §7.1.3)

End the report with a one-paragraph answer, based only on the evidence found: *is this a valuable problem, and is the proposed MVP the smallest credible product experiment?* Cite the problem evidence, the MVP boundary and the items deliberately left out.

## Course activity list (outside the PDF and the spreadsheet)

The teaching staff's Sprint A / B / C activity list is in [checklist.md](./checklist.md). Only the Sprint A part is audited. Sprint B and C activities (Sprint A retrospective, developing stories, the next sprint backlog) are **out of scope**: do not audit them, do not penalise their absence and do not edit their files. Only where a Sprint A criterion asks for a plan (for example the retrospective cadence in the methodology, or the release plan) check that the plan exists in the Sprint A documents. The PDF's Sprint 2 and Sprint 3 deliverables (§7.2, §7.3) are also out of scope.
