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

## 2026-11-17

Facilitada por Luis Santos. Entrada registada a 2026-11-21.

| Pessoa | Ontem | Hoje | Bloqueios |
|---|---|---|---|
| Luis Santos | Integrou a US-01 (PR #96) e o PostgreSQL na porta 5433 (PR #97); atualizou o README e o Sprint Backlog; atribuiu a US-15 e a US-20 a si e a US-02 e a US-03 ao Pedro Soares | Tornar obrigatória a revisão do code owner em todos os PRs; criar as tags de versão automáticas; preparar a VM de produção na Azure e a pipeline de deploy; rever o planeamento (PR #99) | Nenhum reportado |
| Pedro Soares | Sem progresso desde a daily de 16/11 | Fechar no PR #99 a retrospetiva do Sprint A, a capacidade, o refinamento, a DoR e a distribuição das histórias; implementar a US-15 (#79) | Nenhum reportado |
| Pedro Costa | Sem progresso desde a daily de 16/11 | Rever o planeamento (PR #99) | Nenhum reportado |
| Marco Garcia | Sem progresso desde a daily de 16/11 | Sem trabalho atribuído | Nenhum reportado |
| Leonardo Costa | Sem progresso desde a daily de 16/11 | Sem trabalho atribuído | Nenhum reportado |

**Por atribuir:** US-09 (#84) e US-23 (#86).

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

## 2026-11-19

Facilitada por Luis Santos. Entrada registada a 2026-11-21.

| Pessoa | Ontem | Hoje | Bloqueios |
|---|---|---|---|
| Luis Santos | Integrou a daily de 18/11 (PR #107), o template de defects (PR #104) e a imagem privada do GHCR (PR #110); reviu os PRs #108 e #109; abriu o PR #111 (credencial OIDC); atribuiu a US-03 ao Leonardo Costa | Rever o PR #108 (US-09) até poder ser integrado; continuar a US-20 (#85) | Nenhum reportado |
| Pedro Soares | Integrou a pipeline de deploy (PR #103) e as verificações antes de produção (PR #109); abriu o PR #108 (US-09) e respondeu à revisão; reviu os PRs #104, #107 e #110 | Fechar a revisão do PR #108; rever o PR #111; registar o refinamento de 19/11 e distribuir as histórias seguintes; ignorar as verificações de produção em PRs só de `docs/` (#115) | Nenhum reportado |
| Pedro Costa | Avançou a US-02 (#80) no branch da história | Abrir o PR da US-02 (#80); rever o refinamento de 19/11 | Nenhum reportado |
| Marco Garcia | Sem progresso desde a daily de 18/11 | Trabalhar na US-23 (#86) | Nenhum reportado |
| Leonardo Costa | Sem progresso desde a daily de 18/11 | Trabalhar na US-03 (#81) | Nenhum reportado |

## 2026-11-20

Facilitada por Luis Santos. Entrada registada a 2026-11-21.

| Pessoa | Ontem | Hoje | Bloqueios |
|---|---|---|---|
| Luis Santos | Reviu e integrou o PR #108, o que fechou a US-09 (#84) | Implementar a US-20 (#85) e a US-23 (#86), que troca com o Marco Garcia pela US-25 (#90), e abrir os PRs; rever os PRs #116, #119 e #120 | Nenhum reportado |
| Pedro Soares | Respondeu à revisão do PR #108; integrou a credencial OIDC (PR #111) e o refinamento de 19/11 (PR #114); atribuiu a US-05 e a US-22 ao Pedro Costa e a US-13 e a US-28 a si; abriu o PR #116 (#115) | Rever e integrar o PR #112 (US-02); corrigir o defect #105 | Nenhum reportado |
| Pedro Costa | Abriu o PR #112 (US-02); aprovou o PR #114; atribuiu a US-10 ao Leonardo Costa, a US-24 ao Marco Garcia e a US-25 ao Luis Santos | Acertar as versões do Alembic da US-02 (#80) para o PR #112 poder ser integrado | Nenhum reportado |
| Marco Garcia | Sem progresso desde a daily de 19/11 | Trabalhar na US-23 (#86) e na US-24 (#89) | Nenhum reportado |
| Leonardo Costa | Sem progresso desde a daily de 19/11 | Trabalhar na US-03 (#81) e na US-10 (#88) | Nenhum reportado |

## 2026-11-21

Facilitada por Luis Santos.

| Pessoa | Ontem | Hoje | Bloqueios |
|---|---|---|---|
| Luis Santos | Abriu os PRs da US-20 (#121) e da US-23 (#122); reviu os PRs #116 e #119; integrou o PR #120, o que fechou o defect #105 | Responder à revisão dos PRs #121 e #122 e integrá-los; rever e integrar os PRs #119, #123 e #124; corrigir as respostas sem permissão de administrador na US-01 (#125); registar as dailies em falta | Nenhum reportado |
| Pedro Soares | Integrou a US-02 (PR #112), o que fechou a #80; corrigiu o defect #105 (PR #120) | Abrir os PRs da #115 (substitui o #116) e da US-13 (#87); rever os PRs #121, #122 e #126 | Nenhum reportado |
| Pedro Costa | Acertou as versões do Alembic da US-02 (#80) | Trabalhar na US-05 (#82) e na US-22 (#83) | Nenhum reportado |
| Marco Garcia | Sem progresso desde a daily de 20/11 | Trabalhar na US-24 (#89) e na US-25 (#90) | Nenhum reportado |
| Leonardo Costa | Sem progresso desde a daily de 20/11 | Trabalhar na US-03 (#81) e na US-10 (#88) | Nenhum reportado |
