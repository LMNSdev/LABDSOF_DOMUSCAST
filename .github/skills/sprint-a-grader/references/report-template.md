# Report template

Write the report in the user's language (default PT-PT for fix text, English for headings if the user wrote English). Link files with workspace-relative paths and line numbers. Keep it tight. The report covers Sprint A only: never list Sprint B/C work or the PDF's Sprint 2/3 deliverables as gaps.

```markdown
## Sprint A audit

**Verdict:** Ready for 20 | Not ready (N blockers, N gaps)
**Rubric total:** X / 52 = the sum of the 13 scored components (all except "Team presentation"), each 0-4. Show the sum as `a+b+c+...` so it can be checked. **Presentation:** Pass | Fail (pass/fail only, not part of the total).

### 1. Mechanical checks
Errors: N | Warnings: N (paste the grouped summary; list the errors)

### 2. Score table
| # | Component | Score | Evidence | Gap to reach 4 | Fix type |
|---|-----------|-------|----------|----------------|----------|
| 1 | Product vision | 3 | [sprintA.md](docs/sprintA/sprintA.md#L350) | no feasibility argument | write-now |
| ... |

Fix type: `write-now` (derivable from existing docs) or `team-input` (needs facts, evidence or decisions from the team).

### 2b. External claims verified
| Claim (file#line) | Source URL | Date checked | Result (confirmed / contradicted / unverified) |
|---|---|---|---|

Only `contradicted` claims may be reported as errors. `unverified` claims are listed as "could not verify", never as wrong.

### 3. Activity checklist
| Phase | Item | Status | Evidence |

### 3b. Assignment deliverables (PDF §7.1.2) and cross-cutting requirements
| # | Deliverable / requirement | Status | Evidence | Missing parts |
|---|---|---|---|---|

Ten deliverables, then ethical engagement, investor engagement, version control, agile management, delivery and ethics. Finish with the one-paragraph investor-review answer (PDF §7.1.3).

### 4. Inconsistencies
- file#line vs file#line: what disagrees and which one is right

### 5. Prioritized fixes
Ordered by points gained per effort. Each entry: file + section + exact content to add or change (draft text for write-now items, a placeholder and the question for team-input items).

### 6. Blockers for a 20
Only what prevents every component from reaching 4.

### 7. Review before committing (fix mode only)
Changed files (`git status --short`), how to review them (`git diff`), and the line: "Nothing was committed. Review the diff and commit it yourself if you agree." Optionally a suggested commit message, labelled as a suggestion.
```

Rules:
- Quote the exact text of every defect you report (a short verbatim excerpt) with its link. A defect you cannot quote does not exist.
- Counts and line numbers come from the checker's Facts section or a fresh read.
- No effort or time estimates. Print the report in chat; do not write files into the repository.
- Do not report "Ready for 20" unless every component scores 4, the checker has zero errors, no assignment deliverable is Missing or Partial, and the presentation passes.
- Do not claim a score without citing evidence.
- Separate what is wrong from what is merely missing evidence.
