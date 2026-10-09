# Sprint A - Descoberta, Validação e Design

## Índice
- [0. Processo e Metodologia de Equipa](#0-processo-e-metodologia-de-equipa)
- [1. Relatório de Problema e Oportunidade](#1-relatório-de-problema-e-oportunidade)
- [2. Análise de Mercado e Concorrência](#2-análise-de-mercado-e-concorrência)
- [3. Investigação de Utilizadores](#3-investigação-de-utilizadores)
- [4. Rascunho de Requisitos](#4-rascunho-de-requisitos)
- [5. Product Vision](#5-product-vision)
- [6. Product Backlog](#6-product-backlog)
- [7. Responsible AI Opportunity Assessment](#7-responsible-ai-opportunity-assessment)
- [8. Technical Design](#8-technical-design)
- [9. Architecture Decision Records](#9-architecture-decision-records)
- [10. Security and Privacy Assessment](#10-security-and-privacy-assessment)
- [11. Walking Skeleton](#11-walking-skeleton)

---

## 0. Processo e Metodologia de Equipa

### Metodologia
- Framework ágil: Scrum, com sprints alinhados aos do enunciado (Sprint 1/2/3), dailies curtas, sprint review com os docentes (investidores) no final de cada sprint, e retrospetiva da equipa.

### Controlo de versões (Git) - GitHub Flow
- Estratégia: **GitHub Flow**, uma única branch de longa duração, `main` (como branch de production), mais uma branch de curta duração por funcionalidade/tarefa. Nunca se commita diretamente em `main`.
- Formato da mensagem de commit: `[#<id>] - <descrição>` (ex.: `[#12] - Adiciona formulário de reporte de fuga de água`), onde `#<id>` é o identificador da issue/task associado(a).

![GitHub Flow: branch principal `main` sempre estável, branches de funcionalidade curtas, integradas de volta via PR após code review e deployment/CI](./github_flow.png)

### Gestão de issues
- Ferramenta: GitHub Issues/Projects com cada issue referenciada nos commits e PRs.

### Papéis da equipa
Todos os 4 membros implementam código (frontend/backend), a tabela indica apenas a responsabilidade **adicional** de cada um, para além do desenvolvimento comum a todos.

| Membro | Responsabilidade adicional | Detalhe |
|---|---|---|
| Membro 1 | Product Owner / PM | Product Backlog, prioridades, contacto com investidores (docentes) |
| Membro 2 | Business Analyst | Levantamento de requisitos, pesquisa de mercado/utilizador |
| Membro 3 | QA | Estratégia e execução de testes |
| Membro 4 | DevOps / Scrum Master | Pipeline de CI/CD, facilitação do processo ágil |
| Membro 5 | Backend Developer | Desenvolve e mantem a lógica do código, bases de dados, e APIs que alimentam a App|
| Membro 6 | Frontend Developer | Desenvolve a parte visual e interativa da App |

### Definition of Ready (DoR)
Uma User Story está pronta para entrar num sprint quando: tem critérios de aceitação claros e testáveis; não depende de nenhuma outra tarefa; está estimada pela equipa (temporalmente); o seu impacto e valor agregado é compreendido sem ambiguidade por todos.


### Definition of Done (DoD)
Uma User Story está concluída quando: o código foi implementado e aprovado em code review (PR revisto, e aprovado, por, pelo menos, 1 pessoa); a pipeline de CI passa (build, testes automatizados, linting/análise estática); tem testes automatizados relevantes; foi integrada em `main`; a documentação relevante foi atualizada; e cumpre os critérios de aceitação definidos.

---

## 1. Relatório de Problema e Oportunidade

### Comunidade-alvo
Moradores de prédios de habitação multifamiliar autogeridos em Portugal (regime de propriedade horizontal), tipicamente entre 8 e 60 frações, com administrador eleito de entre os condóminos (não uma empresa profissional de gestão).

**Utilizadores primários:** condóminos (proprietários e inquilinos) e o administrador do condomínio.

**Beneficiários secundários:** comissão de condóminos, prestadores de manutenção (canalizador, eletricista, elevadores), porteiro/funcionário (quando existe).

### Problema
Os condomínios coordenam problemas do edifício (fuga de água, luz da escada fundida, elevador avariado, etc.) normalmente através de um grupo de WhatsApp ou posters espalhados pelo prédio. No entanto, esta gestão traz alguns problemas, que se agravam quanto mais tempo ficam por resolver:
- Mensagens perdem-se no meio de conversa não relacionada;
- Não há estado do pedido, pedidos repetidos e incerteza sobre se algo já foi tratado, o que permite que avarias simples se agravem por falta de acompanhamento (ex.: uma fuga de água não reportada a tempo causa danos estruturais e custos de reparação muito maiores);
- Sem histórico auditável para o administrador (prioridades, prova de diligência na resolução), o que o expõe a risco legal/de seguro acrescido em caso de acidente (ex.: queda por avaria não reportada nem resolvida);
- Quem gere o grupo é normalmente um voluntário sem ferramentas de apoio, o que gera desgaste, perda de confiança dos condóminos (mesmo quando está a tentar resolver os problemas) e dificulta encontrar quem aceite o cargo no futuro;
- Os posters junto ao elevador ficam desatualizados, são removidos ou simplesmente não chegam a inquilinos/residentes que raramente passam por ali;
- Decisões tomadas em assembleias de condóminos não chegam a quem falta (por doença, viagem, horário), a informação passa "de boca em boca" e é frequentemente distorcida ou incompleta, sem ata acessível e centralizada, diminuindo a transparência e o sentido de comunidade, e aumentando conflitos entre vizinhos;
- Privacidade fraca nos grupos de WhatsApp: os números de telefone pessoais de todos os moradores ficam expostos a todo o grupo, sem alternativa mais privada.

### Mapa de stakeholders
| Stakeholder | Papel | Relação com o produto |
|---|---|---|
| Condómino (proprietário/inquilino) | Vive no edifício, quer problemas resolvidos e visibilidade | Utilizador principal, reporta e acompanha |
| Administrador do condomínio | Responsável pela manutenção das partes comuns | Utilizador principal, triagem, atribuição, fecho |
| Comissão de condóminos | Supervisiona o administrador, aprova despesas maiores | Consulta histórico/relatórios |
| Prestadores de manutenção | Executam a reparação | Utilizador indireto (fora do MVP) |
| Funcionário/porteiro | Pode reportar em nome de residentes | Reportador secundário |
| Seguradora | Pode exigir prova de incidente/diligência | Beneficiário indireto do histórico |
| Município/fornecedores de utilities | Relevantes quando o problema é externo ao prédio | Fora do MVP; caminho de escalonamento futuro |

### Evidência do problema
- **TODO:** fazer questionario/forms + procurar em foruns 

### Pressupostos e riscos

**Pressupostos**:
- A maioria dos residentes tem smartphone e ligação à internet suficiente (dados móveis/Wi-Fi) para usar a app;
- Existe sempre um administrador no prédio (já é uma exigência legal em Portugal), que faz a configuração inicial e cria as contas dos residentes;
- Um único prédio já é "comunidade" suficiente para o produto gerar valor, sem depender de adoção multi-prédio.

**Riscos e mitigações:**

Cada risco abaixo está ligado a um pressuposto ou a um problema identificado na secção anterior, para garantir que nenhum fica sem mitigação.

| Risco | Mitigação |
|---|---|
| Custo de mudança do WhatsApp (grátis, já instalado) | Onboarding em segundos: administrador cria as contas e dá a cada residente um QR code para associar a sua conta por scan |
| Residentes sem smartphone, menos digitais ou idosos ficam excluídos | Interface acessível, reporte assistido por vizinho/administrador |
| Exclusão de residentes com deficiência visual ou auditiva | Seguir princípios de acessibilidade (WCAG): suporte a leitor de ecrã, texto alternativo em fotos, alternativas não sonoras às notificações |
| Administrador sente perda de controlo | Posicionar como redução de esforço, não canal extra a vigiar |
| Dados pessoais dos residentes mal geridos ou guardados sem necessidade | Minimização de dados: guardar só o essencial (ex.: fração), sem perfis completos nem retenção além do necessário (RGPD) |

---

## 2. Análise de Mercado e Concorrência

TODO: Adicionar dados/fontes/evidências concretas do texto segundo a pesquisa realisada

*Método: revisão dos sites oficiais dos principais produtos (setembro 2026) + observação direta do statu quo. Os dados de lojas de apps e datas de lançamento indicados abaixo devem ser validados antes da entrega final.*

**Achado da pesquisa de trabalhos relacionados:** as soluções digitais de gestão de condomínio existentes (ex.: TownSq, Condo Control, Buildium a nível internacional; Gecond, SolidSoft GC, GOcondomínios em Portugal) são construídas à volta da **gestão de dinheiro** (quotas, contabilidade, pagamentos, orçamentos) e da **governança** (votações, atas), não da **gestão de problemas/informação** do dia a dia (reportar e acompanhar uma avaria, por exemplo). É esse o espaço que a nossa app ocupa.

### 2.1 Quadro comparativo de alternativas e concorrentes

| Alternativa | Utilizadores-alvo | Funcionalidades principais | Pontos fortes | Pontos fracos | Modelo de negócio | UX e privacidade | Diferenciação da nossa proposta |
|---|---|---|---|---|---|---|---|
| **WhatsApp/Messenger, posters, papel** | Qualquer grupo, sem configuração nem literacia digital exigida | Mensagens de grupo em tempo real; posters físicos; folha de papel para reportar avarias | Adoção imediata e custo zero; papel acessível a não-digitais | Mensagens perdem-se, sem estado do pedido nem histórico; posters desatualizam-se ou somem | N/A (ferramentas genéricas gratuitas) | Familiar mas caótica para triagem; números de telefone expostos a todo o grupo | Pedidos com estado, dono e histórico, sem perder a simplicidade do chat |
| **Software de gestão profissional** (GOcondomínios, GCondomPro, SolidSoft GC; int.: TownSq, Condo Control, Buildium) | Administradores profissionais / gestoras de portefólio | Faturação, quotas, contas correntes, atas de assembleia, gestão de ocorrências (backoffice) | Robustez legal/financeira, documentação centralizada | Caro e complexo para 1 prédio autogerido; foco em dinheiro/governança, não em avarias do dia a dia | SaaS B2B por subscrição, dependente do nº de frações | Corporativa e com curva de aprendizagem íngreme; RGPD estabelecido | Foco na coordenação do dia a dia, com onboarding e preço adequados a 1 prédio |
| **Plataformas comunitárias genéricas** (redes de vizinhança) | Vizinhança em geral, sem hierarquia de prédio | Feed social, recomendação de prestadores locais, alertas de segurança, mensagens privadas | Sentido de comunidade, recomendação de prestadores locais | Sem a figura do administrador nem tickets/estado para avarias | Grátis, financiado por publicidade geolocalizada | Orientada a engajamento social, não a tarefas; privacidade moderada/baixa | Estrutura à volta do edifício (propriedade horizontal), com administrador e pedidos com estado |
| **Software de tickets de manutenção** (UpKeep, Fixflo) | Facility managers, senhorios profissionais | Abertura e despacho de tickets, SLA, manutenção preventiva | SLA rigoroso, despacho de fornecedores, manutenção preventiva | Sem dimensão comunitária; exige conta e input técnico para algo trivial | SaaS B2B por ativo/unidade gerido | Profissional, formulários técnicos; sem foco em privacidade entre vizinhos | Reporte em segundos, sem formação técnica nem contrato empresarial |
| **Gecond** ("o meu condomínio") | Condóminos de prédios com administração já cliente do backend | Votação antecipada em assembleias; registo e acompanhamento de avarias | Votação antecipada + registo de avarias na mesma app | Só por convite (B2B2C); avaliação muito baixa nas lojas de apps (1,7/5) | B2B2C, vendido à administração | Inconsistente entre prédios; confiança baixa (rating) | Adotável diretamente por qualquer administrador voluntário, sem depender de terceiro |
| **My LDC** (Loja do Condomínio) | Condóminos e administrador, relação direta | Consulta de informação do condomínio, pedidos, referência MB para pagamento | Gratuita, foco em transparência, referência MB para pagamentos | Sem atualizações desde 2017; possível abandono (a validar) | Gratuito, sustentabilidade não divulgada | Simples mas datada; sem política de privacidade pública | Mantém a proposta de transparência, mas com manutenção ativa e pedidos com estado |
| **Unitify** (smart building) | Administradoras profissionais e novos empreendimentos | Controlo de acesso, intercomunicador de vídeo, contadores inteligentes, cobrança de quotas por fração | UX moderna, pagamentos MB WAY/Multibanco, foco em Portugal | Exige investimento em hardware (controlo de acesso, intercomunicadores) | Pagamentos via Multibanco/MB WAY + Stripe | Moderna, mas dependente de fornecedores de hardware/pagamento terceiros | Sem hardware exigido, adotável por qualquer prédio de baixo orçamento |

### 2.2 Conclusão e oportunidade de diferenciação

Não existe, no mercado português, um produto pensado de raiz para o administrador voluntário de um condomínio pequeno/médio autogerido: os concorrentes diretos assumem uma administração profissional já cliente (Gecond), um pacote financeiro completo e pesado (software de gestão profissional), ou investimento em hardware smart (Unitify). O WhatsApp continua a ganhar por defeito, não porque seja bom, mas porque é a única opção com fricção zero.

**Oportunidades de diferenciação:**
1. Gestão de problemas/informação do dia a dia, não de dinheiro ou governança.
2. Foco no residente (reportar em segundos), não no gestor/contabilidade.
3. Zero-configuração para um único prédio autogerido, sem depender de terceiros nem de hardware.
4. Privacidade por desenho: visibilidade limitada aos residentes/administrador relevantes, sem expor contactos pessoais.

### 2.3 Proposta de Valor

> Para administradores voluntários e condóminos de prédios autogeridos em Portugal (regime de propriedade horizontal), que hoje coordenam avarias e avisos através de grupos de WhatsApp caóticos ou posters físicos desatualizados, o [Nome do Produto] é uma aplicação de gestão de problemas e comunicação de condomínio que transforma conversas dispersas em pedidos estruturados com estado, dono e histórico. Ao contrário do software de gestão profissional de condomínios (focado em contabilidade e governança) e das soluções "smart building" (que exigem hardware e investimento), o nosso produto é gratuito/low-cost, de configuração imediata para um único prédio, e desenhado para o residente, com privacidade por desenho (sem exposição de números de telefone nem perfis completos além do essencial).

---

## 3. Investigação de Utilizadores

### Método

A investigação combina três fontes complementares:

1. **Inquérito online** (Google Forms, distribuído pela rede da equipa e em grupos de Facebook/Reddit de moradores portugueses), ver questionário abaixo.

2. **Leitura de reviews de apps concorrentes** nas lojas Google Play e App Store (foco: Gecond, "o meu condomínio", SolidSoft GC, My LDC), recolhendo padrões de queixas e elogios recorrentes.

3. **Observação informal** - os quatro membros da equipa habitam ou têm familiares em prédios autogeridos em Portugal; as situações descritas foram observadas diretamente (grupos de WhatsApp saturados, posters rasgados no elevador, administrador contactado por SMS ou chamada pessoal).

### Questionário

**Secção A - Perfil**
1. Qual é o seu papel no condomínio? *(Proprietário residente / Inquilino / Administrador / Outro)*
2. Quantas frações tem o seu prédio aproximadamente? *(Menos de 8 / 8–30 / 31–60 / Mais de 60)*
3. O seu prédio tem administração profissional ou é autogerido por um condómino eleito? *(Profissional / Condómino voluntário / Não sei)*

**Secção B - Comunicação atual**

4. Como comunica habitualmente avarias ou problemas do prédio? *(Grupo de WhatsApp/Messenger / Poster/aviso físico no prédio / Contacto direto com o administrador / E-mail / App dedicada / Outro)*
5. Com que frequência reporta um problema no prédio? *(Nunca / Raramente (1–2x/ano) / Às vezes (3–6x/ano) / Frequentemente (>6x/ano))*
6. Depois de reportar um problema, costuma saber se foi resolvido? *(Sim, sou sempre informado/a / Às vezes / Raramente / Nunca)*

**Secção C - Frustrações (escala 1 = nada frustrado, 5 = muito frustrado)**

7. "As minhas mensagens perdem-se no meio de outras conversas no grupo."
8. "Não sei se o problema que reportei já foi ou vai ser tratado."
9. "O mesmo problema é reportado várias vezes por pessoas diferentes."
10. "Não fui avisado/a sobre decisões ou assembleias do condomínio."
11. "O meu número de telefone pessoal fica exposto a todos os membros do grupo."
12. "Os avisos em papel no elevador/hall estão desatualizados ou em mau estado."

**Secção D - Adoção de nova ferramenta**

13. Usaria uma app dedicada ao seu condomínio para reportar avarias e ver avisos? *(Sim, definitivamente / Provavelmente sim / Provavelmente não / Definitivamente não)*
14. O que seria mais importante para decidir usar essa app? *(Ser rápida de usar / Privacidade dos meus dados / Gratuita ou barata / Que os vizinhos também a usassem / Outro)*
15. O que mais o/a inibiria de adotar uma app dessas? *(Mais uma app para instalar / Os vizinhos mais velhos não vão usar / Preocupações com privacidade / Já o WhatsApp chega / Outro)*
16. Quanto estaria disposto/a a pagar por fração, por mês, por um serviço sem publicidade e com privacidade garantida? *(Nada / Até 0,50 € / Até 1 € / Até 2 € / Mais de 2 €)*

**Secção E - Questão aberta**

17. Descreva uma situação concreta em que a comunicação no seu condomínio falhou. *(resposta livre)*

### Resultados

> *A aguardar resultados do inquérito.*

### Limitações

> *A aguardar resultados do inquérito.*

### Decisões de produto resultantes

> *A aguardar resultados do inquérito.*

---

## 4. Rascunho de Requisitos

Esta é uma primeira lista de funcionalidades (agrupadas por epic) e de requisitos não funcionais, resultante da análise de mercado (capítulo 2) e da investigação de utilizadores (capítulo 3). Serve de ponte para a visão de produto (capítulo 5) e será refinada em user stories priorizadas no Product Backlog (capítulo 6), após validação com os clientes (docentes).

A lista completa de requisitos vive num documento próprio, [docs/requisitos.md](../requisitos.md), onde cada funcionalidade/requisito tem uma **versão** e um **estado** (Draft, In Review e Approved), para acompanhar a validação com os clientes ao longo dos sprints sem misturar esse histórico com o resto deste relatório.

**Resumo dos epics propostos (ver detalhe e estado atual em [docs/requisitos.md](../requisitos.md)):**
- **Gestão de avarias:** reportar problema, estado do pedido, histórico do prédio, notificações de estado, deteção de duplicados.
- **Comunicação e governança do condomínio:** mural digital de avisos, calendário de atividades.
- **Privacidade e confiança:** visibilidade do pedido por assunto.
- **Requisitos não funcionais:** usabilidade (rapidez), acessibilidade, privacidade (minimização de dados), segurança (controlo de acesso), observabilidade (monitorização).

---

## 5. Product Vision

---

## 6. Product Backlog

O Product Backlog completo, com prioridade MoSCoW, pontos de história, critérios de aceitação e estado de validação (Draft/In Review/Approved), está em [docs/backlog.md](../backlog.md). As histórias "Must have" são exatamente as que materializam a [proposta de valor](#2-análise-de-mercado-e-concorrência) definida no capítulo 2: transformar o reporte de avarias disperso em pedidos com estado, dono e histórico, com privacidade por desenho.

### 6.1 Objetivos dos sprints

> O detalhe de que user stories entram em cada sprint já está no [plano de release](../backlog.md#2-plano-de-release-inicial-visão-multi-sprint); esta secção regista apenas o objetivo de cada sprint.

- **Sprint A (Descoberta, Validação e Design):** validar que o problema é relevante e que o MVP proposto é o mais pequeno experimento credível; entregar o Walking Skeleton (versão mínima, ponta a ponta).
- **Sprint B (Construir e operar a fatia vertical):** entregar de forma operacional a jornada principal do utilizador, reportar e acompanhar uma avaria, incluindo autenticação (pode ser mock no MVP), armazenamento persistente, pelo menos um workflow assíncrono, a primeira versão da capacidade assistida por IA com fallback não-IA, uma primeira integração com um sistema externo e a demonstração de pelo menos uma condição de falha, conforme exigido para este sprint no enunciado. Este conjunto é o **Sprint B Backlog**, detalhado e confirmado contra a Definition of Ready em [docs/sprintB/backlog.md](../sprintB/backlog.md).
- **Sprint C (Avaliar, consolidar e apresentar):** robustecer e avaliar o que já existe, e consolidar a avaliação formal da capacidade de IA e do cenário de degradação, preparando a apresentação final.

### 6.2 Plano de release inicial

O plano de release multi-sprint (Sprint A/B/C -> entregável -> user stories) está documentado em [docs/backlog.md](../backlog.md#2-plano-de-release-inicial-visão-multi-sprint).

---

## 7. Responsible AI Opportunity Assessment

---

## 8. Technical Design

---

## 9. Architecture Decision Records

---

## 10. Security and Privacy Assessment

---

## 11. Walking Skeleton
