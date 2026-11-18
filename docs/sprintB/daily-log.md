# Daily Log - Sprint B

Registo da daily do Scrum (o que cada pessoa fez, o que vai fazer e bloqueios), uma entrada por dia de trabalho. Complementa o [Sprint Backlog](backlog.md) e serve de evidência do processo.

## Equipa

Luis Santos, Pedro Soares, Pedro Costa, Marco Garcia e Leonardo Costa.

Não há papéis fixos por pessoa: todos fazem de tudo (frontend, backend, testes, pipeline e documentação). Os [papéis do Sprint A](../sprintA/sprintA.md#papéis-da-equipa) descrevem responsabilidades que a equipa partilha, não pessoas. A facilitação da daily (Scrum Master) também roda, e cada entrada diz quem facilitou nesse dia.

## 2026-11-16

Facilitada por Pedro Soares.

| Pessoa | Ontem | Hoje | Bloqueios |
|---|---|---|---|
| Luis Santos | N/A (primeira daily do sprint) | Fechar a capacidade da equipa no Sprint Backlog (16 pontos Must; Should como esforço adicional, sem velocidade histórica) e escolher as histórias a refinar primeiro, pela ordem das dependências; implementar a US-01 e integrá-la | Nenhum |
| Pedro Soares | N/A (primeira daily do sprint) | Facilitar a [retrospetiva do Sprint A](sprintB.md#sprint-a-retrospective) e a sessão de refinamento; criar este registo diário; abrir a issue e o PR do planeamento | O hook `commit-msg` não estava ativo no clone; resolvido com `git config core.hooksPath .githooks` |
| Pedro Costa | N/A (primeira daily do sprint) | Preparar os wireframes das histórias a refinar (US-15, US-02, US-09, US-03, US-20), em falta na DoR | Nenhum |
| Marco Garcia | N/A (primeira daily do sprint) | Rever o contrato técnico das mesmas histórias (endpoints, validações e códigos de erro), a partir de 8.4 e 10.5 | Nenhum |
| Leonardo Costa | N/A (primeira daily do sprint) | Definir, a partir dos critérios de aceitação, que situações de sucesso e de falha cada história tem de provar (ex.: nome repetido na fração dá 409), para fechar a coluna "Validação planeada"; os testes automáticos são escritos depois, na implementação | Nenhum |

**Próximo passo da equipa:** sessão de [refinamento](refinamento.md) a seguir à daily, para fechar a DoR das primeiras histórias.

## 2026-11-18

Facilitada por Luis Santos.

"Ontem" resume a atividade de cada pessoa no GitHub (commits, PRs, revisões e issues) de 17/11 até ao início desta daily; "Hoje" indica o que cada pessoa tem atribuído no GitHub. Horas de Lisboa.

| Pessoa | Ontem | Hoje | Bloqueios |
|---|---|---|---|
| Luis Santos | 17/11: PR #100 (revisão obrigatória do code owner em todos os PRs), integrado às 02:30; revisão do PR #99 (comentários às 02:38 e 02:43, aprovado às 18:25); PR #101 (tags de versão automáticas), aberto às 18:53 e integrado às 20:34, criou a v0.2.4; VM de produção criada na Azure; PR #103 (pipeline de deploy), aberto às 21:47. 18/11: revisão do PR #102 (00:37); defect #105, PR #104 (template de defects), issue #106 e PR #107 (esta daily) | Atribuído: US-20 (#85). PRs abertos: #103, #104 e #107 | Nenhum reportado |
| Pedro Soares | 17/11: issue #98 e PR #99 (retrospetiva do Sprint A, capacidade, daily log, refinamento e DoR das US-02, US-03, US-09, US-15, US-20 e US-23, distribuição das US), integrado às 17:36; aprovou o PR #101 às 20:34; PR #102 (US-15), aberto às 20:39. 18/11: PR #102 integrado às 00:31 e issue #79 fechada; comentário no PR #103 às 00:30 (deploy só em versões principais) | Atribuído: defect #105 | Nenhum reportado |
| Pedro Costa | 17/11: aprovou o PR #99 às 09:44. 18/11: aprovou o PR #102 às 00:29. Sem commits | Atribuído: US-02 (#80) | Nenhum reportado |
| Marco Garcia | Sem atividade no GitHub desde a daily de 16/11 | Atribuído: US-23 (#86) | Nenhum reportado |
| Leonardo Costa | Sem atividade no GitHub desde a daily de 16/11 | Nada atribuído no GitHub | Nenhum reportado. A conta não consta dos colaboradores do repositório |

**Por atribuir:** US-03 (#81) e US-09 (#84).

**Dependência:** o defect #105 (atribuído ao Pedro Soares) depende de uma decisão da US-23 (atribuída ao Marco Garcia): ao remover uma identidade, limpar o `nome_normalizado` ou tornar a restrição única só para identidades ativas.
