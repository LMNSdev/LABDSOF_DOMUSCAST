# Activity checklist and consistency checks

Scope: Sprint A only (see "Scope" in SKILL.md). The Sprint B and Sprint C activity lists are not audited. The "Sprint #B backlog" item below is a Phase 3 activity of Sprint A, so only that backlog file is checked.

## Sprint A activities

Mark each item **Done**, **Partial** or **Missing** and cite the evidence (file#section or screenshot).

### Phase 1
- Git repository set up (GitHub): repo, branching strategy (GitHub Flow), commit convention and hook, PR templates
- Issue tracking set up: issues and project board with screenshots or links; issues referenced in commits and PRs
- Team methodology agreed (Scrum, ceremonies, cadence)
- Definition of Ready written
- Definition of Done written
- Roles identified and assigned (PM, BA, QA, Dev, ...), with who holds which

### Phase 2
- Research on the project domain
- Research on related works (competitors, alternatives)
- Questions for customers elaborated
- Interviews or other elicitation techniques carried out, with limitations documented (never fabricated)
- Initial list of functional requirements (epics/features) and NFRs

### Phase 3
- Functional scope proposal: product vision, personas, epics, general workflow, domain model
- Product backlog created
- Backlog prioritized with the customer (MoSCoW)
- Sprint B backlog created and every item respects the Definition of Ready

### Also required by the criteria
Architecture & technology, assumptions & dependencies, operating costs, prioritized backlog (epics), NFRs, high-level scope of Sprint 1, team presentation.

## Cross-document consistency checks

Run these by hand, in addition to the script:

1. One product name everywhere (README, docs, slides, app, images).
2. Same list and number of components (API, Worker, app, database, shared volume) in sprintA §8, ADRs, `technical-design.drawio`, images, `DomusCast/README.md` and `docker-compose.yml`.
3. Same external provider and model names across §7, §8.6, §8.10, ADR-010, README and code; each name exists in the provider's current official docs (fetch it), and any note such as "unavailable on <date>" next to a price or product is reported as a risk.
4. Domain model entities match the data model (§8.3), API outline (§8.4) and backlog stories.
5. Each story in the Sprint B release plan appears in `docs/sprintB/backlog.md`, with equal points.
6. Each story's endpoints exist in §8.4 and vice versa; no endpoint without a story.
7. NFR identifiers (RNF-nn) and story identifiers (US-nn) do not collide and are traced from requirements to stories.
8. Cost lines match the technologies in the ADRs (no cost for a tool that was dropped, no tool without cost).
9. DoR/DoD wording in the sprintA document, Sprint backlog columns, PR templates and CI workflow agree.
10. Walking skeleton (§11) claims match the repository (CI jobs, tests, compose file, folders).
11. Every ADR has context, decision, alternatives, rationale and consequences, is forward-looking, and predates the code it governs.
12. Index entries and cross-references (`#anchors`, `./relative` links, images) resolve; the rendered text has no leftover merge markers, `TBC`, or TODO.
13. Language: PT-PT consistently, correct accents, no leaked English headings unless they mirror the assignment terms.
14. Documented ethics and integrity: user research is not fabricated; limitations are stated; AI-generated content is declared as reviewed.
