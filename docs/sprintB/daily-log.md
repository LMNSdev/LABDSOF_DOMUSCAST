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

## 2026-11-18

Facilitada por Luis Santos (Scrum Master nesta daily).

| Pessoa | Ontem | Hoje | Bloqueios |
|---|---|---|---|
| Luis Santos | Tags de versão automáticas após cada merge (#101, integrado; criou a v0.2.4); ambiente de produção na Azure (VM, acesso do GitHub por OIDC, orçamento) e pipeline de deploy (#103, em revisão); revisão da US-15 (#102) e registo do defect #105 | Integrar o #103 e acompanhar o primeiro deploy (v0.3.0); template de issue para defects (#104) | Nenhum |
| Pedro Soares | US-15 implementada e integrada (#102): `POST /identidades`, leitura do QR code e ecrã do nome na app, evidências com TalkBack; refinamento e DoR das US-02, US-03, US-09, US-20 e US-23 | A confirmar na daily (proposta: corrigir o defect #105 ou pegar na US-03 ou na US-20, que ficaram para quem acabasse primeiro) | A confirmar na daily |
| Pedro Costa | A confirmar na daily | US-02 (Reportar avaria), conforme a distribuição do [refinamento](refinamento.md) | A confirmar na daily |
| Marco Garcia | A confirmar na daily | US-09 (Privacidade do autor), conforme a distribuição do refinamento | A confirmar na daily |
| Leonardo Costa | A confirmar na daily | US-23 (Remover identidade), conforme a distribuição do refinamento | A confirmar na daily |

**Nota para a US-23:** o defect #105 depende de uma decisão desta história: ao remover uma identidade, limpar o `nome_normalizado` (a pessoa pode voltar a entrar com o mesmo nome) ou tornar a restrição única só para identidades ativas.
