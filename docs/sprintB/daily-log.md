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

"Ontem" resume a atividade de cada pessoa no GitHub (commits, PRs, revisões e issues) a 16/11; "Hoje" indica o que cada pessoa tinha atribuído no GitHub no início de 17/11. Horas de Lisboa.

| Pessoa | Ontem | Hoje | Bloqueios |
|---|---|---|---|
| Luis Santos | 16/11: issue da US-01 (#73), criada às 02:20; commits do README e da coluna Prioridade no Sprint Backlog (00:42 e 01:03); US-01: commits da API (criar condomínio, listar frações, gerar QR code), da app (criar condomínio, QR code por fração, navegação por separadores) e das evidências (02:20 a 02:22); CI com o Flutter 3.47 (02:44); PR #96 (US-01), aberto às 02:47 e integrado às 02:55, o que fechou a #73; PR #97 (PostgreSQL na porta 5433), aberto às 03:25 e integrado às 03:28; atribuiu a si a US-15 (#79) e a US-20 (#85) e ao Pedro Soares a US-02 (#80) e a US-03 (#81) (02:27 a 02:39) | Atribuído: US-15 (#79) e US-20 (#85) | Nenhum reportado |
| Pedro Soares | Sem atividade no GitHub a 16/11 | Atribuído: US-02 (#80) e US-03 (#81) | Nenhum reportado |
| Pedro Costa | Sem atividade no GitHub a 16/11 | Nada atribuído no GitHub | Nenhum reportado |
| Marco Garcia | Sem atividade no GitHub a 16/11 | Nada atribuído no GitHub | Nenhum reportado |
| Leonardo Costa | Sem atividade no GitHub a 16/11 | Nada atribuído no GitHub | Nenhum reportado |

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

"Ontem" resume a atividade de cada pessoa no GitHub (commits, PRs, revisões e issues) de 18/11, depois da daily anterior, até ao fim do dia; "Hoje" indica o que cada pessoa tinha atribuído no GitHub no início de 19/11. Horas de Lisboa.

| Pessoa | Ontem | Hoje | Bloqueios |
|---|---|---|---|
| Luis Santos | 18/11: PR #107 (daily de 18/11) integrado às 13:47; revisão do PR #109 (comentários às 13:53 e às 14:31), aprovado e integrado às 14:32; revisão do PR #108 (comentários às 14:11); PR #104 (template de defects) integrado às 14:23; PR #110 (imagem privada do GHCR), aberto às 14:02 e integrado às 14:24; PR #111 (credencial OIDC), aberto às 14:34; atribuiu a US-03 (#81) ao Leonardo Costa às 14:09 | Atribuído: US-20 (#85). PR aberto: #111 | Nenhum reportado |
| Pedro Soares | 18/11: aprovou o PR #107 às 09:59; aprovou e integrou o PR #103 (pipeline de deploy) às 10:01; atribuiu a si a US-09 (#84) às 10:20; PR #108 (US-09), aberto às 11:48, com respostas à revisão e novos commits às 14:40; PR #109 (verificações antes de produção), aberto às 12:06, com respostas à revisão às 14:04, integrado às 14:32; comentários no PR #104 (13:58 e 13:59), aprovado às 14:22; revisão do PR #110 (alterações pedidas às 14:10, aprovado às 14:23) | Atribuído: US-09 (#84) e defect #105. PR aberto: #108 | Nenhum reportado |
| Pedro Costa | 18/11: commits da US-02 (#80) enviados para o branch `feature/us-02-reportar-avaria` (19:18 e 19:34) | Atribuído: US-02 (#80) | Nenhum reportado |
| Marco Garcia | Sem atividade no GitHub desde a daily de 18/11 | Atribuído: US-23 (#86) | Nenhum reportado |
| Leonardo Costa | Sem atividade no GitHub desde a daily de 18/11 | Atribuído: US-03 (#81) | Nenhum reportado |

## 2026-11-20

Facilitada por Luis Santos. Entrada registada a 2026-11-21.

"Ontem" resume a atividade de cada pessoa no GitHub (commits, PRs, revisões e issues) a 19/11; "Hoje" indica o que cada pessoa tinha atribuído no GitHub no início de 20/11. Horas de Lisboa.

| Pessoa | Ontem | Hoje | Bloqueios |
|---|---|---|---|
| Luis Santos | 19/11: revisão do PR #108 (comentários à 01:14 e às 14:22), aprovado às 14:23 e integrado às 14:24, o que fechou a US-09 (#84) | Atribuído: US-20 (#85) e US-25 (#90) | Nenhum reportado |
| Pedro Soares | 19/11: respostas à revisão do PR #108 e 2 commits (5xx guarda o reporte na fila offline; Flutter do CI em Docker) às 10:30 e 10:32; aprovou e integrou o PR #111 às 16:08; issue #113 e PR #114 (refinamento de 19/11), aberto às 21:25 e integrado às 21:41; atribuiu a US-05 (#82) e a US-22 (#83) ao Pedro Costa e a si a US-13 (#87) e a US-28 (#91) (21:42 a 21:45); issue #115 e PR #116 (ignorar as verificações de produção em PRs só de `docs/`), aberto às 21:56 | Atribuído: US-13 (#87), US-28 (#91), defect #105 e issue #115. PR aberto: #116 | Nenhum reportado |
| Pedro Costa | 19/11: 6 commits da US-02 (#80) entre as 00:14 e as 23:13; PR #112 (US-02), aberto às 21:02; aprovou o PR #114 às 21:39; atribuiu a US-10 (#88) ao Leonardo Costa, a US-24 (#89) ao Marco Garcia e a US-25 (#90) ao Luis Santos às 23:05 | Atribuído: US-02 (#80), US-05 (#82) e US-22 (#83). PR aberto: #112 | Nenhum reportado |
| Marco Garcia | Sem atividade no GitHub a 19/11 | Atribuído: US-23 (#86) e US-24 (#89) | Nenhum reportado |
| Leonardo Costa | Sem atividade no GitHub a 19/11 | Atribuído: US-03 (#81) e US-10 (#88) | Nenhum reportado |

## 2026-11-21

Facilitada por Luis Santos.

"Ontem" resume a atividade de cada pessoa no GitHub (commits, PRs, revisões e issues) a 20/11; "Hoje" indica o que cada pessoa tinha atribuído no GitHub no início de 21/11. Horas de Lisboa.

| Pessoa | Ontem | Hoje | Bloqueios |
|---|---|---|---|
| Luis Santos | 20/11: revisão do PR #116 (comentários às 15:02 e 15:05); revisão do PR #119 às 15:02, commit no branch do PR (psycopg 3, 15:08) e comentário às 15:15; aprovou e integrou o PR #120 às 15:03, o que fechou o defect #105; trocou no GitHub a US-23 (#86), que passou do Marco Garcia para si, e a US-25 (#90), que passou de si para o Marco Garcia (18:47); 13 commits da US-20 e da US-23 (19:19 a 20:09); PR #121 (US-20), aberto às 19:50; PR #122 (US-23), aberto às 20:09 | Atribuído: US-20 (#85) e US-23 (#86). PRs abertos: #121 e #122 | Nenhum reportado |
| Pedro Soares | 20/11: aprovou o PR #112 às 09:21 e integrou-o às 09:22, o que fechou a US-02 (#80); PR #120 (defect #105), aberto às 09:45 e integrado às 15:03 | Atribuído: US-13 (#87), US-28 (#91) e issue #115. PR aberto: #116 | Nenhum reportado |
| Pedro Costa | 20/11: commit da US-02 (#80) às 00:39 (versões do Alembic) | Atribuído: US-05 (#82) e US-22 (#83) | Nenhum reportado |
| Marco Garcia | Sem atividade no GitHub a 20/11 | Atribuído: US-24 (#89) e US-25 (#90) | Nenhum reportado |
| Leonardo Costa | Sem atividade no GitHub a 20/11 | Atribuído: US-03 (#81) e US-10 (#88) | Nenhum reportado |

A atividade de 21/11 (merges dos PRs #121 a #124 e a issue #125) entra na próxima daily.
