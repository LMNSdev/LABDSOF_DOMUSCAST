# Style guide and coherence checklist

For the writing review of the Sprint A documents. Language: **PT-PT, post-1990 Orthographic Agreement (AO90)**. Examples are in Portuguese because that is the language of the documents.

## 1. Language baseline

### Spelling the project already uses (keep it)
`ação`, `atual`, `projeto`, `objetivo`, `retrospetiva`, `receção`, `facto` (the `c` is kept in PT-PT), `contacto`, `ecrã`, `telemóvel`, `utilizador`, `ficheiro`, `equipa`, `carregar` / `descarregar`, `palavra-passe`, `condómino` (with the accent).
The script counts the AO90 forms against the pre-1990 forms. Any pre-1990 form (`acção`, `actual`, `projecto`, `objectivo`, `retrospectiva`, `directo`, `óptimo`) is a **Corrigir**.

### Brazilian forms to flag (PT-PT equivalent in brackets)
`usuário` (utilizador), `tela` (ecrã), `celular` (telemóvel), `equipe` (equipa), `contato` (contacto), `arquivo` as a computer file (ficheiro), `baixar` (descarregar), `salvar` (guardar), `deletar` (apagar), `rodar` (executar/correr), `gerenciar` (gerir), `compartilhar` (partilhar), `você`/`vocês` in formal text (use the impersonal form), `a gente`, `se conectar` (ligar-se), progressive gerund (`estou fazendo` should be `estou a fazer`). `arquivado` (archived) is fine.

### Anglicisms
Accept the course and industry terms the documents already use as names: *Sprint, Product Backlog, Sprint Backlog, Walking Skeleton, DoR, DoD, MoSCoW, issue, commit, pull request, mockup, wireframe, feedback, backlog*. Rules:
- One spelling per term in the whole set (`Product Backlog` or `product backlog`, not both). Capitalise a term only if it names an artefact and do it everywhere.
- Flag an English word only when the same text already uses a natural PT-PT word and mixes both (`prazo` / `deadline`, `alvo` / `target`, `desempenho` / `performance`, `configuração` / `setup`).
- English terms are italicised or not, but consistently.

### Frequent PT-PT errors to look for
- Agreement: noun–adjective, subject–verb (especially with long subjects and with `haver` impersonal: `há`, not `hão`).
- `a` / `à` / `há` (time: `há dois dias`, `daqui a pouco`); `mais` / `mas`; `porque` / `porquê` / `por que` / `por quê`; `onde` / `aonde`; `a fim de` / `afim`; `se não` / `senão`; `de` / `do` before an infinitive.
- Pronoun placement: proclisis after `que`, `não`, `já`, `só` and other attractors (`que se cria`, `não o vê`); enclisis otherwise (`cria-se`, `fá-lo`).
- Gerund vs `a` + infinitive: PT-PT prefers `estar a fazer`, `ao fazer`.
- Overused connectors: `através de` (use `por`, `com`, `por meio de` when it fits), `de forma a`, `ao nível de`, `em termos de`.
- Accents on verbs and nouns (`têm` plural of `tem`, `vêem` is pre-AO90 and should be `veem`, `condómino`).
- Repeated words and words missing after an edit (`de de`, `que que`, a verb without a subject).

### Punctuation and typography
- No space before `,` `;` `:` `.` `!` `?`; one space after. No comma before `e` linking two items in a list (no serial comma).
- One quotation style per document (straight `"` or `«»` or `“”`), not a mix.
- One dash style (` - ` or ` – `) for the same job.
- Decimal comma (`0,27`), thousands separated by a space (`2 000`), percentages written one way (`80%` or `80 %`), a space between number and unit (`15 min`, `1 h`, `4 GB`). Money: `US$ 0,27`, `5,99 €`; keep the project's pattern.
- Dates: one pattern per context. ISO (`2026-10-23`) in tables and `22/10/2026` in prose is acceptable if it is applied consistently; flag the mix only when it is inconsistent inside the same table or paragraph.
- Do not touch code spans, endpoints, field names, URLs, identifiers or quoted text.

## 2. Clarity
- One idea per sentence. Report sentences above about 40 words; suggest where to split (usually at a `;` or `:`).
- Avoid stacked parentheses and long chains of `de` (`a gestão da documentação dos requisitos do sistema de reportes`).
- Prefer the active voice and a concrete subject (`o Worker envia`, not `é efetuado o envio`).
- Define every acronym at first use in each document (`DoR`, `SLI`, `RGPD`...). The script lists candidates without an expansion; ignore the ones the audience obviously knows.
- Avoid vague words that carry no information: `etc.`, `diversos`, `alguns`, `vários`, `adequado`, `robusto`, unless a number or example follows.
- Lists and tables: parallel wording (all items start with a noun, or all with a verb), one punctuation rule per list, headers named in the same way.
- A paragraph that starts a section should say what the section is for.

## 3. Coherence checklist (not technical)

Read for these on every pass. A coherence defect is a **Corrigir** when two places contradict each other and a **Melhorar** when the wording only drifts.

1. **Same thing, same name.** One term per concept across all files. Candidates observed in this project (confirm with the authors, some may be intentional):
   - `quadro de avisos` and `mural`;
   - `assembleia` and `reunião` (the data model and the API say `reunião`, the stories and the narrative say both);
   - `condómino`, `residente` and `morador`;
   - `utilizador` and `usuário`;
   - `reporte`, the project term for a problem report, versus `report` or `reporte` used as a verb;
   - `app` and `aplicação`;
   - the product name (`DomusCast` everywhere, never `Domus Cast`), persona names, role names and sprint names (`Sprint A`, `Sprint 1`, `Sprint #B`).
   If two terms are meant to differ, the text must define the difference once.
2. **Same fact, same value.** Every figure that appears in more than one place agrees in the text: number of stories and ADRs, points, percentages, durations, dates, section numbers cited. Report the disagreement with both quotes. Do not judge which value is technically right.
3. **Cross-references lead where they say.** `ver 7.4` goes to a section about that; a table or figure caption describes what is in it; a promised section exists; the index matches the headings.
4. **Promise and delivery.** The introduction of a document or section announces what follows and the section delivers it, in the same order.
5. **Order and flow.** Problem, then evidence, then decision, then consequence. A section does not rely on a term defined further down without a link.
6. **Tense and voice.** Plans in the future or the conditional, design in the present, what already happened in the past. Do not mix within a paragraph. In an architecture decision record, the wording reads as a decision taken before the work (a wording check, not a technical one).
7. **Register and person.** One person across the document: impersonal, or `a equipa`, or `nós`. No `tu`/`você` in formal text.
8. **Evidence and tone.** Absolute claims (`nunca`, `sempre`, `o melhor`, `único`) and superlatives need a support in the text; hedges (`hipótese`, `proposta`, `estimativa`) are kept wherever the same claim is repeated and are not dropped in the summary. Report as wording, not as a technical verdict.
9. **Structure.** One heading-numbering style (`2.1` or `2.1.`, not both), no skipped levels, one list style (capitals and full stops), the same order of columns for the same kind of table, bold and italic used for one purpose.
10. **Duplication.** The same paragraph or table in two files: suggest keeping one and linking to it.
11. **Between documents.** Epic names, story titles, requirement names and the glossary agree across `sprintA.md`, `backlog.md`, `requisitos.md` and `sprintB/backlog.md`.

## 4. What is not a defect
- Course and industry terms in English, code, identifiers, endpoints and quoted sources.
- A deliberate placeholder written for the team (`A PREENCHER`): report only if the sentence around it is unclear.
- Style preferences that do not hurt clarity or consistency: put them under **Sugestão** or leave them out.
