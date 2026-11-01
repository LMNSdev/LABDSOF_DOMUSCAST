# Report template

Write the feedback in PT-PT, in the chat, in the tone of a teacher marking a report: specific, fair and kind. Link files with workspace-relative paths and line numbers. Quote the exact text of every point (a short verbatim excerpt). A point you cannot quote does not exist. Do not create files in the repository.

```markdown
## Feedback de escrita - Sprint A

**Âmbito:** ficheiros revistos e o que ficou de fora. **Idioma:** PT-PT (AO90).

### O que está bom
Um ou dois pontos concretos, com a localização (por exemplo, "a secção 7 explica a decisão em linguagem clara e com exemplos").

### Avaliação por dimensão
| Dimensão | Nível | Porquê (uma linha) |
|---|---|---|
| Correção linguística (ortografia, gramática, pontuação) | Bom | ... |
| Clareza (frases, vocabulário, siglas) | Razoável | ... |
| Coerência interna (nomes, números, remissões) | Razoável | ... |
| Terminologia | Razoável | ... |
| Estrutura e legibilidade (títulos, listas, tabelas) | Bom | ... |

Níveis: Insuficiente, Razoável, Bom, Muito bom. Sem nota numérica.

### Corrigir
Erros e contradições. Agrupa os repetidos numa só entrada, com a contagem.
| # | Onde | Texto atual | Problema | Correção sugerida |
|---|---|---|---|---|
| 1 | [sprintA.md](docs/sprintA/sprintA.md#L303) | "### 5.1. Personas" | Numeração dos títulos com ponto final aqui e sem ponto nos restantes (6 contra 26) | Uniformizar: "### 5.1 Personas" |

### Melhorar
Texto pouco claro, pesado ou inconsistente. Mesma tabela.

### Sugestão
Preferências de estilo. Curto, no máximo 5 pontos.

### Coerência entre documentos
Termos ou valores que variam de um ficheiro para outro. Para cada um, as duas citações e a proposta de uniformização.
| Conceito | Variantes encontradas (ficheiro:linha) | Proposta |
|---|---|---|

### Fora do âmbito (no máximo 3)
Algo que parece tecnicamente duvidoso. Sem veredicto; recomenda a skill `sprint-a-grader`.

### Para o autor responder
Frases ambíguas em que não sei o que se pretende dizer. Pergunta direta, uma por ponto.

### Próximo passo
As 3 correções que mais melhoram o texto, por ordem.
```

Rules:
- Every point states the file, the line, the exact current text, the reason and the smallest correction.
- Counts and line numbers come from the script or a fresh read, never from memory.
- Never edit files or commit. If the user wants the corrections applied, tell them it is a separate request.
- Do not mix technical verdicts into the feedback.
- If a category has nothing to report, say so in one line instead of an empty table.
