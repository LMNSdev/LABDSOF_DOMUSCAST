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

![GitHub Flow: branch principal `main` sempre estável, branches de funcionalidade curtas, integradas de volta via PR após code review e deployment/CI](./images/github_flow.png)

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

### 5.1. Personas

- **Administrador Voluntário** (ex.: "Rui", 58, reformado/ativo, eleito em assembleia): 
  -  É um inquilino eleito para gerir o prédio, não pertecendo a uma empresa profissional de gestão. Faz esta gestão nas horas livres e não possui ferramentas de apoio. Sente regularmente dificuldade em fazer a triagem dos problemas e em provar a sua diligência na resolução dos mesmos perante os outros inquilinos. Precisa de uma solução para gerir as ocorrências e registar o histórico de decisões e reparações.

- **Condómino Residente Ocupado** (ex.: "Marta", 34, proprietária):
    - É proprietária de uma fração e trabalha fora de casa, pelo que acompanha o grupo do prédio de forma intermitente e raramente consegue estar presente nas assembleias. Quer poder reportar um problema em poucos segundos e saber, sem ter de perguntar a ninguém, se já foi comunicado e tratado. Sente dificuldade em perceber o estado dos problemas do edifício e depende de terceiros para saber o que foi decidido nas assembleias a que falta.

- **Inquilino/Residente Recente** (ex.: "Tiago", 25, inquilino):
    - Vive no prédio há pouco tempo, raramente passa pelo hall e não conhece bem os vizinhos, pelo que nunca chegou a ver os avisos afixados nem está necessariamente incluído no grupo de WhatsApp. Quer receber apenas os avisos que lhe dizem respeito e conseguir reportar um problema sem constrangimento e sem expor o seu número de telefone a todo o prédio. A sua dor principal é a falta de informação, porque muitas vezes só sabe que houve uma avaria ou uma decisão depois de o problema já o ter afetado.

- **Condómino Sénior Pouco Digital** (ex.: "D. Amélia", 76, proprietária):
    - Vive no prédio há muitos anos, usa um telemóvel com poucas funcionalidades e confia sobretudo no papel e no contacto presencial para se informar. Quer continuar a saber o que se passa no prédio e poder comunicar um problema sem depender de tecnologia que não domina. Sente-se frequentemente excluída, porque os posters ficam desatualizados e a informação lhe chega "de boca em boca", muitas vezes incompleta ou distorcida.


### 5.2. Proposta de Valor

- Para administradores voluntários e condóminos de prédios autogeridos, a nossa plataforma transforma a gestão do dia a dia do edifício de uma fonte de stress para um processo simples e colaborativo;

- Em vez de recorrer a ferramentas genéricas onde as mensagens perdem-se facilmente, estruturamos a comunicação em pedidos com estado, responsável e histórico auditável, e levamos avisos e decisões de assembleias a todos os residentes, incluindo quem falta ou raramente passa pelo hall onde fica normalmente o poster físico;

- Diferenciamo-nos do software de administração profissional ao deixar deliberadamente de fora a contabilidade e a gestão financeira, concentrando-nos na resolução rápida dos problemas do prédio e na privacidade dos residentes, sem hardware nem custos de adoção para o administrador.


**Proposta de Valor por Persona**:

| Persona                        | Valor principal                                                          |
|--------------------------------|--------------------------------------------------------------------------|
| Administrador Voluntário       | Menos esforço de triagem e um histórico que prova a sua diligência       |
| Condómino Residente Ocupado    | Reportar em segundos e saber o estado sem perguntar a ninguém            |
| Inquilino / Residente Recente  | Receber os avisos relevantes e reportar sem expor o seu telemóvel        |
| Condómino Sénior Pouco Digital | Não ficar excluído da informação do prédio, através do reporte assistido |

### 5.3. User Journey

Cada jornada corresponde a um workflow modelado em diagrama de atividade com raias por ator ([workflows.drawio](workflows.drawio)), e está ligada às user stories do backlog.

- **Onboarding do condomínio (Workflow 1, US-01)**: O administrador cria o condomínio, indicando o nome e o número de frações, e a aplicação gera um QR code único por fração, que pode ser partilhado por todos os residentes dessa fração. O administrador distribui o QR code aos residentes e cada residente faz scan com a aplicação. Se o QR code for válido, o sistema associa o residente à fração, sem partilhar contactos pessoais, e o residente passa a aceder à aplicação. Se for inválido, é mostrado um erro;

![alt text](<images/1. Onboarding do condominio.drawio.svg>)

- **Reportar e acompanhar uma avaria (Workflow 2, US-02, US-03, US-04, US-05, US-08, US-09, US-11)**: O residente escolhe "Reportar avaria", descreve o problema e, opcionalmente, junta uma fotografia com texto alternativo, acessível a leitores de ecrã. O backend valida o pedido (campos obrigatórios, anexos e autenticação) e, se for inválido, o residente corrige-o. Um pedido válido é guardado no estado "Aberto – pendente de triagem", com o residente como reporter, visível apenas a ele e ao administrador, e a submissão é confirmada. O administrador vê o pedido novo e analisa-o: se for duplicado, associa-o ao pedido original, o autor passa a co-reporter e o pedido novo é fechado como duplicado; se o problema já estiver resolvido, fecha-o como "Resolvido" com uma nota; caso contrário, aceita-o como pedido novo e trata-o (Workflow 3). Cada decisão é registada no histórico e o reporter e os co-reporters são notificados, por notificação push com alternativa visual. O residente consulta "Os meus pedidos" para ver o estado, a data de criação e a data da última atualização;

![alt text](<images/2. Reportar e acompanhar avaria.drawio.svg>)

- **Acompanhar e resolver pedidos (Workflow 3, US-04, US-05, US-14)**: O administrador abre a lista única de pedidos, filtra por estado e analisa cada pedido. Se o pedido representar um risco para os residentes, cria um aviso ligado ao pedido (título, texto e local), que é publicado no quadro de avisos e notifica todos os residentes, mantendo o pedido privado. O administrador altera o estado do pedido (Aberto, Em curso, Resolvido) e acrescenta uma nota. O sistema regista cada alteração com data, hora e autor, num histórico imutável, e notifica o residente. Quando o pedido é resolvido, o aviso ligado a ele é arquivado e fica no histórico de avisos;

![alt text](<images/3. Acompanhar e resolucao (admin).drawio.svg>)

- **Agendar assembleias e lembretes (Workflow 4, US-13, NFR-01)**: O administrador agenda a assembleia (data, hora e local) e a reunião é guardada localmente no telemóvel. Sem internet, fica numa fila local e sincroniza automaticamente quando a ligação regressar. Com internet, o evento é sincronizado com o Google Calendar ou, se este estiver indisponível, com um calendário alternativo (iCal/Outlook ou simulador). Se nenhum estiver disponível, a aplicação entra em modo degradado: usa os dados locais, mostra um aviso visível, regista o erro e volta a tentar mais tarde. É agendado um lembrete antes da reunião (por exemplo, 24 horas antes) e os residentes veem a reunião no calendário e recebem o lembrete;

![alt text](<images/4. Reuniao e calendario.drawio.svg>)

- **Ata da assembleia assistida por IA (Workflow 5, US-10, NFR-01)**: Depois da assembleia, o administrador grava ou carrega o ficheiro de áudio, que é guardado no telemóvel e, sem internet, fica numa fila local até a ligação regressar. Com o serviço de IA disponível, este gera a transcrição e um rascunho da ata, marcado como "gerado por IA, pendente de revisão". O administrador revê, edita e aprova a ata, e só então ela é publicada aos residentes, incluindo os que faltaram. Se o serviço de IA estiver indisponível, o áudio mantém-se guardado e a transcrição é repetida mais tarde, e o administrador é avisado e pode escrever a ata manualmente;

![alt text](<images/5. Ata da assembleia por IA.drawio.svg>)

- **Quadro de avisos (Workflow 6, US-06, US-07, US-14)**: O administrador publica um aviso, geral ou ligado a um pedido existente, sem expor o reporter. Os residentes consultam o quadro de avisos a partir do ecrã principal, com os mais recentes primeiro, e podem consultar os avisos antigos no histórico;

![alt text](<images/6. Quadro de avisos.drawio.svg>)

### 5.4. Critérios de Sucesso

> Este projeto é de âmbito académico e o produto não será lançado em ambiente real nem testado com utilizadores externos. Os critérios abaixo são verificados pela própria equipa de desenvolvimento, através de testes automatizados (unitários, de integração e end-to-end), de cenários de demonstração com dados sintéticos, de testes de carga e acessibilidade em ambiente controlado e de uma avaliação de usabilidade. Estes critérios demonstram que o produto cumpre o que foi desenhado, mas não provam que os utilizadores reais beneficiam dele. Qualquer medição de tempo feita pela equipa reflete utilizadores experientes e conhecedores da aplicação, pelo que é apenas indicativa. 

- **Velocidade e eficiência**: O residente tem de conseguir reportar qualquer problema em menos de 1 minuto, mesmo com uma ligação à internet fraca. Este critério será verificado por um teste end-to-end automatizado que executa a jornada de reporte com a rede limitada por simulação de ligação lenta, confirmando que a jornada se conclui dentro de um orçamento de tempo definido e com um número reduzido de passos (a fixar no protótipo, com a hipótese de, no máximo, 5 interações). Os tempos serão também cronometrados pela equipa, sendo apenas indicativos;

- **Valor com utilização mínima**: A plataforma deverá gerar valor imediato mesmo que apenas o administrador e alguns residentes a utilizem, assumindo que pelo menos um residente assume o papel de administrador da aplicação no prédio. Este critério será validado por um cenário de demonstração com um edifício fictício (um administrador e alguns residentes com dados sintéticos), em que as jornadas de reporte e de triagem se concluem sem depender de mais utilizadores, e em que a criação do prédio e o convite dos primeiros residentes são concluídos em poucos passos. A adoção por uma percentagem das frações em contexto real fica como hipótese de produto;

- **Privacidade nativa e retenção**: Os dados pessoais serão geridos de acordo com o RGPD. Cada pedido é visível apenas ao reporter, aos co-reporters e ao administrador, os avisos ligados a pedidos não expõem o reporter, e a associação por QR code não partilha contactos pessoais. Este critério será verificado por testes automatizados de autorização que confirmam estas regras de visibilidade, pela implementação de um período de retenção dos dados (incluindo os ficheiros de áudio das assembleias) com teste automatizado da sua aplicação, e pelo uso exclusivo de dados sintéticos em todo o projeto;

- **Redução do ruído comunicacional**: Pretende-se que nenhum pedido duplicado fique em aberto e que se elimine a incerteza sobre se um problema já foi tratado, por oposição à experiência atual em ferramentas como o WhatsApp. Este critério será verificado por testes de integração que confirmam que um pedido fechado como duplicado fica associado ao original, que o autor passa a co-reporter e que ambos são notificados, e por um cenário com guião em que a equipa procura saber se uma avaria já foi tratada, primeiro numa conversa de WhatsApp simulada com mensagens de ruído e depois em "Os meus pedidos", comparando o número de passos e se a resposta é encontrada sem ambiguidade;

- **Transparência do estado dos pedidos**: Cada pedido deve ter sempre um estado atualizado e visível ao residente que o reportou. Este critério será verificado por testes automatizados de integração que confirmam que 100% das alterações de estado geram uma entrada no histórico e uma notificação ao residente (e aos seguidores do pedido), com o tempo de entrega da notificação medido em ambiente de teste e com valor-alvo a definir no Technical Design;

- **Capacidade de resposta do administrador**: A plataforma deve reduzir o esforço de triagem do administrador. Este critério será avaliado por um cenário com guião em que um membro da equipa, no papel de administrador, faz a triagem do mesmo conjunto de pedidos simulados, primeiro numa conversa de WhatsApp simulada e depois na aplicação, comparando o número de passos, o tempo gasto e o número de pedidos esquecidos ou mal classificados. O resultado é indicativo, porque quem executa a tarefa conhece a aplicação;

- **Alcance das decisões e avisos**: As convocatórias, atas e avisos devem chegar também a quem faltou. Este critério será verificado por testes automatizados que confirmam que cada aviso, convocatória e ata publicados ficam acessíveis a todos os residentes do condomínio e geram a notificação correspondente, e por um cenário com guião em que a equipa localiza a decisão de uma assembleia simulada no quadro de avisos, comparando o número de passos com a procura da mesma informação numa conversa de WhatsApp simulada;

- **Inclusão e acessibilidade**: Os residentes menos digitais ou com limitações de visão ou audição não devem ficar excluídos. Este critério será verificado por uma revisão com ferramentas automáticas de acessibilidade e por uma verificação manual das jornadas principais com leitor de ecrã e navegação por teclado, tendo como referência os critérios WCAG 2.1 de nível AA, e pela confirmação de que o reporte assistido permite concluir a jornada de reporte em nome de outro residente. A equipa fará ainda uma avaliação heurística de usabilidade das jornadas principais, com base nas heurísticas de Nielsen;

- **Fiabilidade e degradação controlada**: O produto deve continuar a ser útil quando algo falha. Este critério será verificado por testes de resiliência com falhas injetadas, que demonstram que, com o serviço de IA indisponível, o áudio é preservado e a ata pode ser escrita manualmente, que, com o Google Calendar indisponível, a aplicação recorre ao calendário alternativo e, se nenhum estiver disponível, entra em modo degradado com aviso visível, e que, sem internet, as reuniões e os áudios ficam em fila local e sincronizam quando a ligação regressa. Mede-se ainda a disponibilidade e a latência (percentil 95) da submissão de pedidos num ambiente de teste containerizado sujeito a carga simulada, com valores concretos a definir no Technical Design.

- **Qualidade da ata assistida por IA**: O rascunho de ata gerado a partir do áudio deve ser útil e fiável, e nunca deve ser publicado sem aprovação humana. Este critério será avaliado num conjunto de assembleias simuladas, gravadas pela equipa a partir de guiões com decisões conhecidas, com origem e limitações documentadas, comparando o rascunho com uma ata de referência escrita pela equipa. Serão medidas a percentagem de decisões do guião corretamente captadas, o número de informações inventadas por ata, a taxa de erro de palavras da transcrição e o tempo de processamento, com critérios de aceitação a fixar na avaliação de oportunidade de IA. A alternativa sem IA, a ata escrita manualmente, serve de baseline, e um teste automatizado confirma que a publicação fica bloqueada enquanto o rascunho estiver "pendente de revisão".
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
