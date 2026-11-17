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
| Luis Santos | N/A (primeira daily do sprint) | Fechou a capacidade da equipa no Sprint Backlog (compromisso com os 16 pontos Must; Should como esforço adicional, sem velocidade histórica); reviu valor/âmbito da US-15 | Nenhum |
| Pedro Soares | N/A (primeira daily do sprint) | Criou este registo diário; facilitou a [retrospetiva do Sprint A](sprintB.md#sprint-a-retrospective) | Nenhum |
| Pedro Costa | N/A (primeira daily do sprint) | Vai preparar o wireframe do ecrã "pedir o nome" da US-15 (critério "Desenho da interface" em falta na DoR) | Nenhum |
| Marco Garcia | N/A (primeira daily do sprint) | Vai rever o contrato técnico de `POST /identidades` (formato, validações, 409 para nome duplicado) | Nenhum |
| Leonardo Costa | N/A (primeira daily do sprint) | Vai preparar os casos de teste de sucesso/falha da US-15 para fechar a coluna "Validação planeada" | Nenhum |

**Refinamento da US-15 (depois da daily):** a equipa aprovou o [wireframe](design/us-15.html) e decidiu o que faltava no contrato técnico. A API responde 404 tanto a token inválido como a revogado, para não revelar que tokens existiram (TM-01). O limite é de 10 tentativas por hora por IP, acima dos 5 da US-01, porque os vizinhos partilham muitas vezes a rede Wi-Fi do prédio. Cada fração tem no máximo 10 identidades ativas (proposta de 10.5). DoR da US-15 cumprida.

**Próximo passo da equipa:** abrir a branch da US-15 e começar a implementação (API e app).
