# Daily Log - Sprint B

Registo da daily do Scrum (o que cada pessoa fez, o que vai fazer e bloqueios), uma entrada por dia de trabalho. Complementa o [Sprint Backlog](backlog.md) e serve de evidência do processo.

## Equipa e papéis

Mapeamento proposto a partir dos papéis definidos em [sprintA.md](../sprintA/sprintA.md#papéis-da-equipa); a equipa confirma ou ajusta.

| Pessoa | Papel |
|---|---|
| Pedro Soares | DevOps / Scrum Master |
| Luis Santos | Product Owner / PM + Business Analyst |
| Pedro Costa | Frontend Developer |
| Marco Garcia | Backend Developer |
| Leonardo Costa | QA |

## 2026-11-16

Facilitada por Pedro Soares (Scrum Master).

| Pessoa | Ontem | Hoje | Bloqueios |
|---|---|---|---|
| Luis Santos | N/A (primeira daily do sprint) | Fechar a capacidade da equipa no Sprint Backlog (16 pontos Must; Should como esforço adicional, sem velocidade histórica) e escolher as histórias a refinar primeiro, pela ordem das dependências; implementar a US-01 e integrá-la | Nenhum |
| Pedro Soares | N/A (primeira daily do sprint) | Facilitar a [retrospetiva do Sprint A](sprintB.md#sprint-a-retrospective) e a sessão de refinamento; criar este registo diário; abrir a issue e o PR do planeamento | O hook `commit-msg` não estava ativo no clone; resolvido com `git config core.hooksPath .githooks` |
| Pedro Costa | N/A (primeira daily do sprint) | Preparar os wireframes das histórias a refinar (US-15, US-02, US-09, US-03, US-20), em falta na DoR | Nenhum |
| Marco Garcia | N/A (primeira daily do sprint) | Rever o contrato técnico das mesmas histórias (endpoints, validações e códigos de erro), a partir de 8.4 e 10.5 | Nenhum |
| Leonardo Costa | N/A (primeira daily do sprint) | Definir, a partir dos critérios de aceitação, que situações de sucesso e de falha cada história tem de provar (ex.: nome repetido na fração dá 409), para fechar a coluna "Validação planeada"; os testes automáticos são escritos depois, na implementação | Nenhum |

**Próximo passo da equipa:** sessão de [refinamento](refinamento.md) a seguir à daily, para fechar a DoR das primeiras histórias.
