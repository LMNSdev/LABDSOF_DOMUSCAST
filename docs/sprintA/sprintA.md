# Sprint A - Descoberta, Validação e Design

## Índice
- [0. Processo e Metodologia de Equipa](#0-processo-e-metodologia-de-equipa)
- [1. Relatório de Problema e Oportunidade](#1-relatório-de-problema-e-oportunidade)
- [2. Análise de Mercado e Concorrência](#2-análise-de-mercado-e-concorrência)
- [3. Investigação de Utilizadores](#3-investigação-de-utilizadores)
- [Rascunho de Requisitos](#rascunho-de-requisitos)
- [4. Product Vision](#4-product-vision)
- [5. Product Backlog](#5-product-backlog)
- [6. Responsible AI Opportunity Assessment](#6-responsible-ai-opportunity-assessment)
- [7. Technical Design](#7-technical-design)
- [8. Architecture Decision Records](#8-architecture-decision-records)
- [9. Security and Privacy Assessment](#9-security-and-privacy-assessment)
- [10. Walking Skeleton](#10-walking-skeleton)

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
| Membro 1 | Product Owner / PM | Backlog, prioridades, contacto com investidores (docentes) |
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

## Rascunho de Requisitos

### Funcionalidades principais

### Outros requisitos importantes

---

## 4. Product Vision

---

## 5. Product Backlog

### 5.1 Backlog priorizado (User Stories)

> Legenda de prioridade (MoSCoW): **M**ust have · **S**hould have · **C**ould have · **W**on't have (nesta iteração). Estimativas em pontos de história (série de Fibonacci: 1, 2, 3, 5, 8, 13).

| ID | User Story | Prioridade | Pontos | Critérios de aceitação |
|---|---|---|---|---|
| US-01 | Como **administrador**, quero criar a conta do condomínio e gerar um QR code por fração, para que cada residente possa associar a sua conta em segundos. | M | 5 | - [ ] Administrador consegue criar o condomínio com nome e nº de frações.<br>- [ ] É gerado um QR code único por fração.<br>- [ ] O scan do QR code associa o residente à fração correta, sem necessitar de partilhar contacto pessoal.<br>- [ ] Um QR code já associado não pode ser reutilizado por outro residente. |
| US-02 | Como **residente**, quero reportar uma avaria com foto e descrição, para que o administrador saiba do problema sem precisar de o contactar diretamente. | M | 5 | - [ ] Formulário permite descrição (texto) e, opcionalmente, uma foto.<br>- [ ] O pedido fica visível apenas ao administrador e ao autor, não a todo o condomínio.<br>- [ ] O pedido criado fica com estado inicial "Aberto".<br>- [ ] O residente recebe confirmação de que o pedido foi submetido. |
| US-03 | Como **residente**, quero consultar o estado do meu pedido, para saber se já está a ser tratado sem ter de perguntar ao administrador. | M | 3 | - [ ] A lista de pedidos do residente mostra o estado atual (Aberto/Em curso/Resolvido).<br>- [ ] Cada pedido mostra a data de criação e da última atualização.<br>- [ ] O estado atualiza automaticamente quando o administrador o altera. |
| US-04 | Como **administrador**, quero ver todos os pedidos do condomínio numa lista única, para priorizar e evitar duplicados. | M | 5 | - [ ] A lista mostra todos os pedidos com estado, data e fração de origem.<br>- [ ] A lista pode ser filtrada por estado.<br>- [ ] Pedidos semelhantes reportados por vários residentes são visualmente agrupados ou sinalizados. |
| US-05 | Como **administrador**, quero mudar o estado de um pedido (Aberto → Em curso → Resolvido) e adicionar uma nota, para manter um histórico auditável de diligência. | M | 5 | - [ ] A mudança de estado fica registada com data/hora e autor.<br>- [ ] O histórico de alterações de um pedido é consultável e não pode ser apagado.<br>- [ ] O residente autor do pedido é notificado da mudança de estado. |
| US-06 | Como **administrador**, quero publicar um aviso geral (ex.: corte de água, assembleia), para que chegue a todos os residentes sem depender de posters físicos. | S | 3 | - [ ] O aviso é visível a todos os residentes do condomínio.<br>- [ ] O aviso tem título, texto e data de publicação.<br>- [ ] Os residentes veem os avisos mais recentes primeiro. |
| US-07 | Como **residente**, quero consultar o quadro de avisos do condomínio, para me manter informado mesmo que esteja ausente. | S | 2 | - [ ] O quadro de avisos é acessível a partir do ecrã principal.<br>- [ ] Os avisos antigos permanecem consultáveis (histórico). |
| US-08 | Como **residente com necessidades de acessibilidade**, quero que o reporte de avarias seja utilizável com leitor de ecrã e sem depender só de som, para não ficar excluído da app. | S | 3 | - [ ] Os elementos principais têm texto alternativo/rótulos acessíveis.<br>- [ ] As fotos de avarias têm campo de descrição alternativa.<br>- [ ] As notificações de estado têm alternativa não sonora (visual). |
| US-09 | Como **residente**, quero que o meu número de telefone e dados pessoais não sejam visíveis a outros residentes, para preservar a minha privacidade. | M | 3 | - [ ] Nenhum residente consegue ver o contacto pessoal de outro residente na app.<br>- [ ] Apenas o essencial (ex.: fração) é guardado por residente, sem perfil completo.<br>- [ ] Os dados de um residente removido deixam de ser acessíveis após remoção da conta. |
| US-10 | Como **administrador**, quero carregar o áudio de uma assembleia e obter automaticamente uma transcrição/rascunho de ata, para não ter de a escrever manualmente e garantir que fica acessível a quem faltou (capacidade assistida por IA). | S | 5 | - [ ] O administrador consegue carregar um ficheiro de áudio associado a uma reunião/assembleia.<br>- [ ] O sistema gera uma transcrição/rascunho de ata a partir do áudio.<br>- [ ] O rascunho gerado é claramente identificado como conteúdo gerado por IA, pendente de revisão e aprovação do administrador antes de ser publicado aos residentes.<br>- [ ] Quando o serviço de transcrição está indisponível, o administrador consegue ainda assim publicar uma ata escrita manualmente (fallback não-IA). |
| US-11 | Como **residente**, quero receber uma notificação quando o meu pedido muda de estado, para não ter de verificar manualmente a app. | C | 3 | - [ ] A notificação é enviada na mudança de estado do pedido.<br>- [ ] O residente pode consultar o pedido diretamente a partir da notificação. |
| US-12 | Como **membro da comissão de condóminos**, quero consultar um histórico/relatório dos pedidos resolvidos, para validar a diligência do administrador. | C | 3 | - [ ] A comissão tem acesso de leitura ao histórico de pedidos e ao seu estado.<br>- [ ] O relatório pode ser filtrado por período. |
| US-13 | Como **residente**, quero ver no calendário as reuniões/assembleias do condomínio e receber uma notificação de lembrete antes de cada uma, para não as esquecer nem ficar de fora de decisões importantes (integração com sistema de calendário externo). | S | 3 | - [ ] O administrador consegue agendar uma reunião/assembleia com data, hora e local.<br>- [ ] A reunião agendada é sincronizada com um serviço de calendário externo (ex.: Google Calendar/iCal) ou um simulador realista.<br>- [ ] O residente recebe uma notificação de lembrete antes da reunião (ex.: 24h antes).<br>- [ ] Quando o serviço de calendário externo está indisponível ou devolve dados inválidos, a reunião continua visível na app a partir dos dados guardados localmente. |
| NFR-01 | Como **equipa de produto**, quero que a app continue a funcionar de forma degradada quando um componente externo (transcrição de atas por IA ou serviço de calendário) está indisponível, para que o residente consiga sempre reportar/acompanhar avarias e ver as reuniões agendadas (cenário de degradação). | M | 3 | - [ ] Os fallbacks já definidos em US-10 (ata manual) e US-13 (dados locais) funcionam de facto quando o respetivo serviço externo está em baixo.<br>- [ ] A app comunica ao utilizador, de forma clara e visível, que está a operar em modo degradado, em vez de falhar silenciosamente.<br>- [ ] Cada indisponibilidade fica registada nos logs/observabilidade da equipa, com timestamp e componente afetado. |


---

## 6. Responsible AI Opportunity Assessment

---

## 7. Technical Design

---

## 8. Architecture Decision Records

---

## 9. Security and Privacy Assessment

---

## 10. Walking Skeleton
