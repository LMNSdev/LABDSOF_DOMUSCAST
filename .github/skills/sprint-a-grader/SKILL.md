---
name: sprint-a-grader
description: "Use when asked to audit, review, grade or verify that the LABDSOF Sprint A (Sprint 1 / M1) documentation is complete and good enough for the top grade (20) under the official M1 rubric, or to fix gaps found. Covers Sprint A only (never Sprint B/C deliverables). Scores 14 rubric components 0-4 with evidence, runs a mechanical doc checker (broken links/anchors, merge markers, placeholders, table errors, backlog acceptance criteria, Sprint B backlog consistency, pptx slide dump), checks the Phase 1-3 activity list and cross-document consistency, and lists the exact fix to reach level 4. Never commits. Trigger words: sprint A, M1, rubric, criteria, grade 20, is everything done, what is missing, verify documentation, Definition of Ready, Definition of Done, product vision, personas, domain model, backlog, NFRs, operating costs, team presentation."
argument-hint: "Optional: components to audit (e.g. 'DoR, DoD, costs'), or 'fix' to apply fixes that need no new team facts"
---

# Sprint A grader (target: 20/20)

Audits the project documentation against the M1 rubric (`labdsof-22-23-m1-criteria.xlsx`) and the Sprint A activity list. Only level **4 - Well-Defined with Justifications** counts as done; any lower level is a gap with a concrete fix.

Default mode is **read-only audit**. Edit files only if the user passes `fix` or explicitly asks for fixes.

## Scope (Sprint A only)

Audit and fix **only Sprint A**. The course activity list puts the Sprint B and C work in later sprints; none of it is graded or edited here.

**In scope (read, grade, and, in fix mode, edit):**
- `docs/sprintA/` (document, drawio sources, images; the `.pptx` is graded but never edited, so list its fixes in the report)
- `docs/backlog.md` and `docs/requisitos.md`
- `docs/sprintB/backlog.md`, **only** because "Create Sprint #B backlog (ensuring Definition of Ready)" is a Phase 3 activity of Sprint A
- `README.md` (root) and `DomusCast/README.md` (the Walking Skeleton documentation)

**Evidence only (read, never edit):** `DomusCast/` source code, `.github/` (workflows, PR templates, dependabot), `.githooks/`, `git log`. Fix mode changes documentation, never code, CI, hooks or templates; a needed change there goes in the report as a recommendation.

**Out of scope (do not grade, do not edit, do not report as a gap):**
- `docs/sprintB/sprintB.md` and `docs/sprintC/sprintC.md` (Sprint A retrospective, developing Sprint B/C user stories, Sprint C and D backlogs)
- The PDF's Sprint 2 and Sprint 3 deliverables (§7.2, §7.3): vertical slice, auth, CI/CD to deploy, AI evaluation results, performance evidence, final pitch, and so on
- Anything about executing or finishing the Sprint B backlog items

A Sprint B/C item counts only where a Sprint A criterion asks for a **plan** for it (for example the retrospective cadence in the methodology, or the release plan). If an in-scope text mentions a later sprint, check that it is consistent, but do not require the later-sprint work to exist.

## Resources (load as needed)

- [Rubric and evidence guide](./references/rubric.md): level descriptors 0-4, sub-criteria and "level 4 test" for each of the 14 components, with where to look in this repo
- [Activity checklist and consistency checks](./references/checklist.md): Phase 1-3 items and cross-document checks
- [Assignment deliverables](./references/assignment-deliverables.md): the 10 Sprint 1 deliverables and cross-cutting requirements of `LABDSOF-26-27-Assignment.pdf` (AI assessment, ethics, investor engagement, security, walking skeleton)
- [Report template](./references/report-template.md): exact output format
- [Doc checker script](./scripts/check_docs.py): mechanical checks, run it first

## Procedure

1. **Run the mechanical checker** from the repo root and keep its output as evidence:
   `python .github/skills/sprint-a-grader/scripts/check_docs.py`
   It prints findings, a "Facts" section (counts, heading outline with line numbers, DoR/DoD/PR-template criteria counts) and the full text of every slide with a topic-coverage table (keyword-based: a hit means the word appears, so confirm in the slide text that the topic is really covered). Errors (exit code 1) are blockers; warnings are reviewed by hand (a placeholder warning can be legitimate product text). If Python is unavailable, do the same checks manually with search tools.
2. **Read the sources, do not grade from memory** (in-scope files only, see Scope): `docs/sprintA/sprintA.md` (in full), `docs/backlog.md`, `docs/requisitos.md`, `docs/sprintB/backlog.md`, `README.md`, `DomusCast/README.md`, `.github/` (PR templates, workflows), `.githooks/`, images in `docs/sprintA/images/`, and the slide dump printed by the checker for `docs/sprintA/presentation/`. Do not open `docs/sprintB/sprintB.md` or `docs/sprintC/`.
3. **Score each component** using [the rubric](./references/rubric.md). Apply the scoring rules below. Audit only the components the user named, if any.
4. **Go through the [checklist](./references/checklist.md)** (Phase 1-3 activity status and cross-document consistency) **and the [assignment deliverables](./references/assignment-deliverables.md)** (the 10 Sprint 1 deliverables of the PDF, plus ethics, AI and investor requirements). The checker's "Assignment deliverables" table only proves a heading exists; read the section before marking Done.
5. **Verify external claims before judging them (mandatory)**: for every price, version, model name, API name, limit and deprecation date in the cost section, §7, §8 and the ADRs, fetch the official page and record URL and date. Never call a name "non-standard", "wrong" or "deprecated" from memory: either verified with a source, or reported as "unverified". Your training knowledge may be older than the document.
6. **Verify order of work** when an ADR or design is claimed to precede code: `git log` shows the ADR commit before the first commit that implements it.
7. **Verify every defect before reporting it**: re-read the exact line with a search or read tool and quote it verbatim in the report. Tool output can hide secret-looking values behind `******`; a masked value is a display artefact, not a defect in the file. Counts, section numbers and line numbers come only from the checker's "Facts" section or a fresh read, never from memory.
8. **Write the report** exactly as in the [template](./references/report-template.md), in the chat. Do not create report files in the repository unless the user asks.

## Scoring rules

- Evidence first: every score cites a file and line (or slide number). No evidence, no points.
- Level 4 needs **all** sub-criteria visibly met **and** the "why" written down. Missing justification caps at 3. Vague or unclear content is 2. Generic or minimal content is 1. Absent is 0.
- Be conservative. When torn between two levels, give the lower one and say what would raise it.
- Length is not quality. Do not reward repetition; do reward specific, measurable, traceable statements.
- Distinguish **documented** from **evidenced** (for example a GitHub board is only evidence if the screenshot or link exists and matches the text).
- `TBC`, `TODO`, `por definir`, empty cells, or placeholders inside a deliverable count as missing for that sub-criterion.
- The "Team presentation" rubric row is empty in the spreadsheet; grade it pass/fail from the checker's full slide text and coverage table: pass only if every required topic is covered and nothing is marked unfinished or contradicts the written documents. Never score it 0-4.
- The M1 rubric has no "user research" row (it is a separate Sprint 1 deliverable). Report missing research results as a separate finding. Cap a rubric component because of it only when the component's own sub-criteria need that evidence (for example personas "representative of the actual target audience"), and say so.
- A deliverable required by the assignment PDF that is missing is a finding even if no rubric row covers it. It lowers a rubric row only when that row's sub-criteria need it (see the last column of the deliverables table).
- Do not give effort or time estimates.
- The spreadsheet repeats the same text for "Suitability" and "Clarity" of the methodology; interpret Suitability as "is the methodology appropriate for this team, product and timeline, and why".

## Integrity rules (never violate)

- Never invent research, interviews, survey results, metrics, dates, feedback or rationale attributed to docentes or customers. If evidence is missing, report the gap and propose a clearly marked placeholder for the team to fill in.
- ADRs must read as decisions taken **before** the code: forward-looking ("serviria, mas...", "exigiria"), never retrospective ("sem ganho que justifique", "já fizemos").
- Do not weaken a rubric criterion to make a score look better, and do not delete justifications to shorten text.
- Documentation language is PT-PT; keep the existing style and terminology (US-nn, MoSCoW, DoR/DoD).
- Do not expose secrets or personal data found while auditing.
- **Never commit, push, amend, stash, reset, tag, open a pull request or otherwise change git history or the remote**, in any mode, even if the user asks to "fix everything" or "finish". The author reviews the changes and, if they agree, commits them personally. Allowed git use is read-only: `status`, `diff`, `log`, `show`, `blame`.

## Fix mode

Apply only fixes that need no new facts from the team (structure, missing cross-references, consistency, formatting, text derivable from existing documents), **and only in in-scope documentation files** (see Scope). Never edit `docs/sprintB/sprintB.md`, `docs/sprintC/`, source code, CI, hooks, PR templates or the `.pptx`. For everything else write a visible placeholder such as `> [A PREENCHER PELA EQUIPA: ...]` and list it in the report. Re-run the checker afterwards and report the before/after score table.

Edits are left **uncommitted in the working tree** for review. Finish the report with:
- the list of changed files (`git status --short`) and how to inspect them (`git diff`);
- a reminder that nothing was committed and that the author must review the diff and commit if they agree;
- if the repository has a commit-message convention or hook (see `.githooks/`), a suggested message the author may use, clearly labelled as a suggestion.
