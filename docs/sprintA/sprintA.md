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
Scrum, com sprints alinhados com o enunciado (Sprint 1/2/3), dailies curtas, sprint review com os docentes (investidores) no fim de cada sprint e retrospetiva da equipa.

### Controlo de versões (Git) - GitHub Flow
- `main` é a branch de produção, sempre estável; nunca se commita diretamente.
- Uma branch curta por funcionalidade/tarefa, integrada em `main` por PR após code review.
- Mensagem de commit: `[#<id>] - <descrição>` (ex.: `[#12] - Adiciona formulário de reporte de fuga de água`), onde `#<id>` é a issue associada.

![GitHub Flow: branch principal `main` sempre estável, branches de funcionalidade curtas, integradas de volta via PR após code review e deployment/CI](./images/github_flow.png)

### Gestão de issues
GitHub Issues/Projects; cada issue é referenciada nos commits e PRs.

### Papéis da equipa
5 membros, 6 papéis (um membro acumula dois). Todos programam frontend e backend; a tabela indica só a responsabilidade **adicional** de cada papel.

| Papel | Responsabilidade adicional |
|---|---|
| Product Owner / PM | Product Backlog, prioridades, contacto com os docentes (investidores) |
| Business Analyst | Requisitos, pesquisa de mercado e de utilizador |
| QA | Estratégia e execução de testes |
| DevOps / Scrum Master | Pipeline de CI/CD, facilitação do processo ágil |
| Backend Developer | Lógica, bases de dados e APIs |
| Frontend Developer | Parte visual e interativa da app |

### Definition of Ready (DoR)
Uma User Story entra num sprint quando: tem critérios de aceitação claros e testáveis; não depende de outra tarefa; está estimada pela equipa; o seu valor é compreendido por todos sem ambiguidade.

### Definition of Done (DoD)
Uma User Story está concluída quando: o PR foi revisto e aprovado por pelo menos 1 pessoa; a CI passa (build, testes automatizados, linting/análise estática); tem testes automatizados relevantes; está integrada em `main`; a documentação foi atualizada; cumpre os critérios de aceitação.

---

## 1. Relatório de Problema e Oportunidade

### Comunidade-alvo
Moradores de prédios de habitação multifamiliar autogeridos em Portugal (propriedade horizontal), tipicamente com 8 a 60 frações e administrador eleito entre os condóminos (não uma empresa de gestão).

- **Utilizadores primários:** condóminos (proprietários e inquilinos) e administrador.
- **Beneficiários secundários:** comissão de condóminos, prestadores de manutenção (canalizador, eletricista, elevadores), porteiro/funcionário.

### Problema
Os problemas do edifício (fuga de água, luz fundida, elevador avariado) coordenam-se por grupo de WhatsApp ou posters no prédio. Consequências, que se agravam com o tempo:
- Mensagens perdem-se no meio de conversa não relacionada.
- Sem estado do reporte: reportes repetidos, incerteza sobre o que já foi tratado, e avarias simples que se agravam (ex.: fuga de água que causa danos estruturais e custos muito maiores).
- Sem histórico auditável: o administrador não prova diligência e fica exposto a risco legal/de seguro (ex.: queda por avaria não resolvida).
- O administrador é um voluntário sem ferramentas: desgaste, perda de confiança dos condóminos e dificuldade em encontrar quem aceite o cargo.
- Posters ficam desatualizados, são removidos ou não chegam a quem raramente passa pelo hall.
- Decisões de assembleia não chegam a quem falta; a informação passa "de boca em boca", distorcida e incompleta, sem ata centralizada, o que reduz a transparência e aumenta conflitos.
- Privacidade fraca: os números de telefone de todos ficam expostos ao grupo.

### Mapa de stakeholders
| Stakeholder | Relação com o produto |
|---|---|
| Condómino (proprietário/inquilino) | Utilizador principal: reporta e acompanha; identifica-se pelo nome (por omissão visível só ao administrador) |
| Administrador do condomínio | Utilizador principal: triagem, atribuição, fecho |
| Comissão de condóminos | Supervisiona o administrador; consulta histórico/relatórios |
| Prestadores de manutenção | Utilizador indireto (fora do MVP) |
| Funcionário/porteiro | Reportador secundário, em nome de residentes |
| Seguradora | Beneficiário indireto do histórico (prova de diligência) |
| Município/fornecedores de utilities | Fora do MVP; escalonamento futuro |

### Evidência do problema
- **TODO (equipa):** questionário/forms e fóruns; registar aqui fontes e resultados.

### Pressupostos e riscos

**Pressupostos:**
- A maioria dos residentes tem smartphone e internet suficiente.
- Existe sempre um administrador (exigência legal em Portugal), que cria o condomínio e gera os QR codes das frações.
- Os residentes aceitam indicar o nome (por omissão visível só ao administrador), para que este os possa contactar.
- O QR code é partilhado pela fração e só associa a fração à identidade criada no primeiro acesso (nome + dispositivo, um dispositivo por pessoa). O nome é autodeclarado e não verificado (ADR-001).
- Um único prédio é "comunidade" suficiente para gerar valor.

**Riscos e mitigações** (cada risco liga a um pressuposto ou problema acima):

| Risco | Mitigação |
|---|---|
| Custo de mudança do WhatsApp (grátis, já instalado) | Onboarding em segundos: QR code por fração, scan e nome |
| Residentes sem smartphone, pouco digitais ou idosos | Interface acessível; um vizinho ou o porteiro reporta por eles com a própria identidade |
| Residentes com deficiência visual ou auditiva | WCAG: leitor de ecrã, texto alternativo nas fotos, alternativas não sonoras às notificações |
| Administrador sente perda de controlo | Posicionar como redução de esforço, não canal extra a vigiar |
| Dados pessoais mal geridos ou guardados sem necessidade | Guardar só fração e nome; retenção limitada (RGPD) |
| QR code divulgado a terceiros | Token aleatório; o administrador revoga/regenera o QR code e remove identidades (US-01, US-09) |
| Nome duplicado ou a fazer-se passar por outro | Nome único por fração; o administrador remove identidades indevidas. Risco aceite como baixo: a fração fica sempre registada (ADR-001) |
| Residentes recusam indicar o nome | Finalidade explicada no ecrã; só o nome é pedido |
| Reportes visíveis a todos expõem dados de terceiros | Aviso no formulário; autor oculto por omissão |

---

## 2. Análise de Mercado e Concorrência

TODO: adicionar dados/fontes/evidências da pesquisa.

*Método: sites oficiais dos principais produtos (setembro 2026) + observação direta. Dados de lojas de apps e datas de lançamento a validar antes da entrega final.*

**Achado principal:** as soluções existentes (TownSq, Condo Control, Buildium a nível internacional; Gecond, SolidSoft GC, GOcondomínios em Portugal) giram à volta da **gestão de dinheiro** (quotas, contabilidade, pagamentos) e da **governança** (votações, atas), não da **gestão de problemas/informação do dia a dia**. É esse o espaço da nossa app.

### 2.1 Quadro comparativo de alternativas e concorrentes

| Alternativa | Utilizadores-alvo e modelo | Pontos fortes | Pontos fracos | Diferenciação da nossa proposta |
|---|---|---|---|---|
| **WhatsApp/Messenger, posters, papel** | Qualquer grupo; gratuito | Adoção imediata, custo zero; papel acessível a não-digitais | Mensagens perdem-se, sem estado nem histórico; posters desatualizam; telefones expostos ao grupo | Reportes com estado, dono e histórico, sem perder a simplicidade do chat |
| **Software de gestão profissional** (GOcondomínios, GCondomPro, SolidSoft GC; int.: TownSq, Condo Control, Buildium) | Administradores profissionais; SaaS B2B por nº de frações | Robustez legal/financeira, documentação centralizada | Caro e complexo para 1 prédio; foco em dinheiro/governança; curva de aprendizagem íngreme | Coordenação do dia a dia, com onboarding e preço para 1 prédio |
| **Plataformas comunitárias genéricas** (redes de vizinhança) | Vizinhança em geral; grátis, publicidade geolocalizada | Sentido de comunidade, recomendação de prestadores | Sem administrador nem tickets/estado; orientada a engajamento; privacidade moderada/baixa | Estrutura à volta do edifício, com administrador e reportes com estado |
| **Tickets de manutenção** (UpKeep, Fixflo) | Facility managers, senhorios; SaaS B2B por ativo | SLA, despacho de fornecedores, manutenção preventiva | Sem dimensão comunitária; formulários técnicos; sem privacidade entre vizinhos | Reporte em segundos, sem formação técnica nem contrato |
| **Gecond** ("o meu condomínio") | Condóminos cujo administrador já é cliente; B2B2C | Votação antecipada + registo de avarias | Só por convite; avaliação 1,7/5 nas lojas; experiência inconsistente | Adotável diretamente por qualquer administrador voluntário |
| **My LDC** (Loja do Condomínio) | Condóminos e administrador; gratuito | Transparência; referência MB para pagamentos | Sem atualizações desde 2017 (possível abandono, a validar); sem política de privacidade pública | Mesma transparência, com manutenção ativa e reportes com estado |
| **Unitify** (smart building) | Administradoras profissionais e novos empreendimentos; Multibanco/MB WAY + Stripe | UX moderna, pagamentos, foco em Portugal | Exige hardware (controlo de acesso, intercomunicadores) | Sem hardware, adotável por qualquer prédio de baixo orçamento |

### 2.2 Conclusão e oportunidade de diferenciação

Não existe em Portugal um produto pensado para o administrador voluntário de um prédio pequeno/médio autogerido: os concorrentes assumem administração profissional (Gecond), pacote financeiro pesado (software profissional) ou hardware (Unitify). O WhatsApp ganha por defeito, por ser a única opção com fricção zero.

**Oportunidades de diferenciação:**
1. Gestão de problemas/informação do dia a dia, não de dinheiro ou governança.
2. Foco no residente (reportar em segundos), não no gestor/contabilidade.
3. Zero-configuração para um prédio, sem terceiros nem hardware.
4. Privacidade por desenho: reportes visíveis a todos para acompanhamento coletivo, sem expor contactos nem o autor (salvo se este escolher mostrar o nome).

### 2.3 Proposta de Valor

> Para administradores voluntários e condóminos de prédios autogeridos em Portugal (propriedade horizontal), que hoje coordenam avarias e avisos por grupos de WhatsApp caóticos ou posters desatualizados, o [Nome do Produto] é uma app de gestão de problemas e comunicação de condomínio que transforma conversas dispersas em reportes estruturados com estado, dono e histórico. Ao contrário do software profissional (contabilidade e governança) e das soluções smart building (hardware), é gratuito/low-cost, de configuração imediata para um prédio, desenhado para o residente e com privacidade por desenho (sem telefones nem perfis além do essencial).

---

## 3. Investigação de Utilizadores

### Método
1. **Inquérito online** (Google Forms, rede da equipa e grupos de Facebook/Reddit de moradores), ver questionário abaixo.
2. **Reviews de apps concorrentes** no Google Play e App Store (Gecond, "o meu condomínio", SolidSoft GC, My LDC): padrões de queixas e elogios.
3. **Observação informal**: membros da equipa vivem ou têm familiares em prédios autogeridos (grupos saturados, posters rasgados, administrador contactado por SMS/chamada).

### Questionário

**A - Perfil**
1. Papel no condomínio *(Proprietário residente / Inquilino / Administrador / Outro)*
2. Nº aproximado de frações *(<8 / 8-30 / 31-60 / >60)*
3. Administração *(Profissional / Condómino voluntário / Não sei)*

**B - Comunicação atual**
4. Como comunica avarias *(WhatsApp/Messenger / Poster / Contacto direto / E-mail / App dedicada / Outro)*
5. Frequência de reportes *(Nunca / 1-2x/ano / 3-6x/ano / >6x/ano)*
6. Fica a saber se foi resolvido? *(Sempre / Às vezes / Raramente / Nunca)*

**C - Frustrações (1 = nada, 5 = muito)**
7. "As minhas mensagens perdem-se no grupo."
8. "Não sei se o problema que reportei vai ser tratado."
9. "O mesmo problema é reportado várias vezes."
10. "Não fui avisado/a sobre decisões ou assembleias."
11. "O meu telefone fica exposto a todo o grupo."
12. "Os avisos em papel estão desatualizados."

**D - Adoção**
13. Usaria uma app dedicada ao condomínio? *(Sim, definitivamente / Provavelmente sim / Provavelmente não / Definitivamente não)*
14. Fator mais importante *(Rapidez / Privacidade / Preço / Vizinhos também usarem / Outro)*
15. Maior inibidor *(Mais uma app / Vizinhos mais velhos não usam / Privacidade / O WhatsApp chega / Outro)*
16. Disposição a pagar por fração/mês, sem publicidade *(Nada / Até 0,50 € / Até 1 € / Até 2 € / Mais de 2 €)*

**E - Aberta**
17. Descreva uma situação em que a comunicação no seu condomínio falhou.

### Resultados
> *A aguardar resultados do inquérito.*

### Limitações
> *A aguardar resultados do inquérito.*

### Decisões de produto resultantes
> *A aguardar resultados do inquérito.*

---

## 4. Rascunho de Requisitos

Primeira lista de funcionalidades (por epic) e requisitos não funcionais, resultante dos capítulos 2 e 3. Faz a ponte para a visão de produto (capítulo 5) e será refinada em user stories no Product Backlog (capítulo 6) após validação com os docentes.

A lista completa vive em [docs/requisitos.md](../requisitos.md), com **versão** e **estado** (Draft, In Review, Approved) por requisito.

**Epics propostos:**
- **Gestão de avarias:** reportar, estado, histórico do prédio, notificações, duplicados, seguir reportes.
- **Comunicação e governança:** mural de avisos, calendário, aviso ligado a reporte, indicador de progresso.
- **Privacidade e confiança:** reportes visíveis a todos com autor oculto por omissão; identificação pelo nome via QR code da fração; gestão de identidades e QR codes pelo administrador.
- **Não funcionais:** rapidez, acessibilidade, minimização de dados, controlo de acesso, observabilidade, resiliência (offline e serviços externos).

---

## 5. Product Vision

### 5.1. Personas

- **Administrador Voluntário** ("Rui", 58, eleito em assembleia): gere o prédio nas horas livres, sem ferramentas. Tem dificuldade em triar problemas e em provar diligência perante os outros. Precisa de gerir ocorrências e registar o histórico de decisões e reparações.
- **Condómina Residente Ocupada** ("Marta", 34, proprietária): trabalha fora, acompanha o grupo de forma intermitente e falta a assembleias. Quer reportar em segundos e saber o estado sem perguntar a ninguém.
- **Inquilino/Residente Recente** ("Tiago", 25, inquilino): raramente passa pelo hall, não conhece os vizinhos nem está no grupo. Quer só os avisos que lhe dizem respeito e reportar sem expor o telefone. Só sabe das avarias e decisões depois de o afetarem.
- **Condómina Sénior Pouco Digital** ("D. Amélia", 76, proprietária): telemóvel básico, confia no papel e no contacto presencial. Quer continuar informada e comunicar problemas sem tecnologia que não domina. Sente-se excluída pelos posters desatualizados e pelo "boca em boca".

### 5.2. Proposta de Valor

- Para administradores voluntários e condóminos de prédios autogeridos, a plataforma transforma a gestão do dia a dia de fonte de stress em processo simples e colaborativo.
- Em vez de ferramentas genéricas onde as mensagens se perdem, estrutura a comunicação em reportes com estado, responsável e histórico auditável, e leva avisos e decisões de assembleia a todos, incluindo quem falta ou raramente passa pelo hall.
- Deixa deliberadamente de fora a contabilidade e a gestão financeira; foca-se na resolução rápida dos problemas e na privacidade, sem hardware nem custos de adoção.

**Valor por persona:**

| Persona | Valor principal |
|---|---|
| Administrador Voluntário | Menos esforço de triagem e um histórico que prova diligência |
| Condómina Residente Ocupada | Reportar em segundos e saber o estado sem perguntar |
| Inquilino / Residente Recente | Receber os avisos relevantes e reportar sem expor o telemóvel |
| Condómina Sénior Pouco Digital | Não ficar excluída, com um vizinho ou o porteiro a reportar e consultar por si |

### 5.3. User Journey

Cada jornada é um workflow em diagrama de atividade com raias por ator ([workflows.drawio](workflows.drawio)), ligado às user stories do backlog.

- **Onboarding do condomínio (Workflow 1, US-01, US-15):** o administrador cria o condomínio (nome, nº de frações) e a app gera um QR code único por fração, partilhado pelos residentes dessa fração. Cada residente faz scan: se o QR code é válido e o dispositivo não tem identidade, a app pede o nome (único na fração) e guarda a identidade no dispositivo, sem pedir contactos; se já existe identidade, não volta a pedir. QR code inválido ou revogado mostra erro.

<!-- TODO (equipa): reexportar o SVG a partir de workflows.drawio (páginas 1 e 2 foram alteradas para incluir o nome do residente) -->
![Onboarding do condominio](images/workflow-1.drawio.png)

- **Reportar e acompanhar uma avaria (Workflow 2, US-02, US-03, US-04, US-05, US-08, US-09, US-11):** o residente descreve o problema e junta, opcionalmente, uma fotografia com texto alternativo. O backend valida (campos obrigatórios, anexos, identidade); se inválido, o residente corrige. O reporte válido fica "Aberto - pendente de triagem", com o residente como autor, visível a todos (o autor só ao administrador, ou a todos se o residente escolher mostrar o nome), e a submissão é confirmada. O administrador vê o reporte com nome e fração e decide: duplicado, fecha-o com "Reporte duplicado do #<id>" e o autor passa a co-reporter do original (que aparece em "Os meus reportes"); já resolvido, fecha-o como "Resolvido" com nota; caso contrário, aceita-o e trata-o (Workflow 3). Cada decisão vai para o histórico e notifica reporter e co-reporters (push com alternativa visual). Os residentes consultam a lista de reportes (filtro "Os meus reportes") com estado, data de criação e última atualização, e podem seguir um reporte para receber notificações (autores e co-reporters seguem automaticamente).

![Reportar e acompanhar uma avaria](images/workflow-2.drawio.png)

- **Acompanhar e resolver reportes (Workflow 3, US-04, US-05, US-14):** o administrador filtra a lista por estado e analisa cada reporte. Se há risco para os residentes, cria um aviso ligado ao reporte (título, texto, local), publicado no quadro de avisos e notificado a todos, sem expor o autor. Altera o estado (Aberto, Em curso, Resolvido) e acrescenta uma nota. Cada alteração fica num histórico imutável com data, hora e autor, e o residente é notificado. Quando o reporte é resolvido, o aviso ligado é arquivado no histórico de avisos.

![Acompanhar e resolver reportes](images/workflow-3.drawio.png)

- **Agendar assembleias e lembretes (Workflow 4, US-13, NFR-01):** o administrador agenda a assembleia (data, hora, local), guardada localmente no telemóvel. Sem internet, fica em fila e sincroniza quando a ligação voltar. Com internet, sincroniza com o Google Calendar ou, se indisponível, com um calendário alternativo (iCal/Outlook ou simulador). Sem nenhum, a app entra em modo degradado: usa os dados locais, mostra um aviso, regista o erro e tenta mais tarde. É agendado um lembrete antes da reunião (ex.: 24 horas) e os residentes veem a reunião no calendário.

![Agendar assembleias e lembretes](images/workflow-4.drawio.png)

- **Ata da assembleia assistida por IA (Workflow 5, US-10, NFR-01):** o administrador grava ou carrega o áudio, guardado no telemóvel e, sem internet, em fila local. Com o serviço de IA disponível, este gera a transcrição e um rascunho de ata marcado como "gerado por IA, pendente de revisão". O administrador revê, edita e aprova; só então a ata é publicada aos residentes, incluindo quem faltou. Com o serviço indisponível, o áudio mantém-se guardado, a transcrição é repetida mais tarde e o administrador é avisado e pode escrever a ata manualmente.

![Ata da assembleia assistida por IA](images/workflow-5.drawio.png)

- **Quadro de avisos (Workflow 6, US-06, US-07, US-14):** o administrador publica um aviso, geral ou ligado a um reporte, sem expor o reporter. Os residentes consultam o quadro a partir do ecrã principal, com os mais recentes primeiro, e os antigos no histórico.

![Quadro de avisos](images/workflow-6.drawio.png)

### 5.4. Critérios de Sucesso

> Projeto académico: o produto não será lançado nem testado com utilizadores externos. Os critérios são verificados pela equipa com testes automatizados (unitários, integração, end-to-end), cenários de demonstração com dados sintéticos, testes de carga e acessibilidade, e avaliação de usabilidade. Mostram que o produto cumpre o que foi desenhado, não que utilizadores reais beneficiam dele. Tempos medidos pela equipa refletem utilizadores experientes e são apenas indicativos.

| Critério | Meta | Verificação |
|---|---|---|
| **Velocidade e eficiência** | Reportar qualquer problema em menos de 1 minuto, mesmo com internet fraca; hipótese de no máximo 5 interações (a fixar no protótipo) | Teste end-to-end com rede lenta simulada e orçamento de tempo definido; cronometragem pela equipa, indicativa |
| **Valor com utilização mínima** | Valor imediato só com o administrador e alguns residentes | Cenário com prédio fictício (dados sintéticos): jornadas de reporte e triagem concluem-se sem mais utilizadores; criar o prédio e convidar residentes em poucos passos. Adoção real por % de frações fica como hipótese |
| **Privacidade nativa e retenção** | RGPD; reportes visíveis a todos mas nome do autor só ao administrador (ou a todos, por escolha); só o nome é recolhido | Testes automatizados de autorização; período de retenção (incluindo áudios) com teste automatizado; só dados sintéticos |
| **Redução do ruído comunicacional** | Nenhum duplicado em aberto; fim da incerteza sobre o que já foi tratado | Testes de integração: duplicado fica ligado ao original, autor passa a co-reporter, ambos notificados; cenário com guião a procurar uma avaria numa conversa de WhatsApp simulada com ruído vs na lista de reportes (nº de passos, ambiguidade) |
| **Transparência do estado** | Cada reporte tem sempre estado atualizado e visível a todos | Testes de integração: 100% das mudanças de estado geram entrada no histórico e notificação ao residente e seguidores; tempo de entrega medido, alvo a definir no Technical Design |
| **Capacidade de resposta do administrador** | Menos esforço de triagem | Cenário com guião: um membro no papel de administrador tria o mesmo conjunto de reportes no WhatsApp simulado e na app (passos, tempo, reportes esquecidos/mal classificados); indicativo |
| **Alcance das decisões e avisos** | Convocatórias, atas e avisos chegam a quem faltou | Testes automatizados: cada publicação fica acessível a todos e gera notificação; cenário com guião a localizar uma decisão no quadro de avisos vs no WhatsApp simulado |
| **Inclusão e acessibilidade** | Pouco digitais e pessoas com limitações de visão/audição não ficam excluídos | Ferramentas automáticas de acessibilidade + verificação manual com leitor de ecrã e teclado (WCAG 2.1 AA); um vizinho conclui o reporte por outro com a própria identidade; avaliação heurística (Nielsen) |
| **Fiabilidade e degradação controlada** | O produto continua útil quando algo falha | Testes de resiliência com falhas injetadas: IA em baixo (áudio preservado, ata manual), Google Calendar em baixo (alternativa, depois modo degradado com aviso), sem internet (fila local e sincronização); disponibilidade e latência p95 da submissão sob carga em ambiente containerizado, valores a definir no Technical Design |
| **Qualidade da ata assistida por IA** | Rascunho útil e fiável, nunca publicado sem aprovação humana | Assembleias simuladas gravadas pela equipa a partir de guiões, comparadas com ata de referência: % de decisões captadas, nº de informações inventadas, taxa de erro de palavras, tempo de processamento (critérios de aceitação a fixar no capítulo 7); ata manual como baseline; teste automatizado confirma bloqueio de publicação enquanto "pendente de revisão" |

---

## 6. Product Backlog

O Product Backlog completo (MoSCoW, pontos, critérios de aceitação, estado Draft/In Review/Approved) está em [docs/backlog.md](../backlog.md). As histórias "Must have" materializam a [proposta de valor](#2-análise-de-mercado-e-concorrência): reportes com estado, dono e histórico, com privacidade por desenho.

### 6.1 Objetivos dos sprints

> As user stories de cada sprint estão no [plano de release](../backlog.md#2-plano-de-release-inicial-visão-multi-sprint).

- **Sprint A (Descoberta, Validação e Design):** validar que o problema é relevante e que o MVP é o experimento mais pequeno credível; entregar o Walking Skeleton (versão mínima ponta a ponta).
- **Sprint B (Construir e operar a fatia vertical):** jornada principal (reportar e acompanhar uma avaria) operacional, com autenticação (mock aceitável), persistência, pelo menos um workflow assíncrono, primeira versão da IA com fallback não-IA, primeira integração externa e demonstração de pelo menos uma condição de falha, como exige o enunciado. Detalhe no [Sprint B Backlog](../sprintB/backlog.md), confirmado contra a Definition of Ready.
- **Sprint C (Avaliar, consolidar e apresentar):** robustecer e avaliar o que existe, consolidar a avaliação formal da IA e do cenário de degradação, preparar a apresentação final.

### 6.2 Plano de release inicial

Ver [docs/backlog.md](../backlog.md#2-plano-de-release-inicial-visão-multi-sprint).

---

## 7. Responsible AI Opportunity Assessment

### 7.1 Fluxo assistido por IA
Transcrição e rascunho de ata (US-10, Workflow 5): o administrador carrega o áudio, o serviço de IA gera transcrição e rascunho marcado como "gerado por IA, pendente de revisão"; o administrador revê, edita e aprova antes da publicação. Serviço/modelo: TODO (equipa).

### 7.2 Valor esperado
Poupa ao administrador voluntário a tarefa morosa de escrever a ata e leva as decisões a quem faltou (capítulo 1).

### 7.3 Riscos e mitigações

| Risco | Mitigação |
|---|---|
| Transcrição ou ata com erros ou informação inventada | Rascunho marcado como IA, editável, aprovação humana obrigatória antes de publicar |
| Prompt injection (instruções ditas em voz alta no áudio) | O texto transcrito é só dados; a IA não tem acesso a ações nem a dados do condomínio |
| Divulgação indevida (vozes e nomes de várias pessoas) | Aviso aos presentes antes de gravar; retenção limitada do áudio; acesso só do administrador |
| Conteúdo impróprio ou difamatório na ata | Revisão e aprovação do administrador antes da publicação |
| Viés (sotaques, nomes próprios, idosos a falar baixo) | Casos difíceis no conjunto de avaliação, medidos separadamente |

### 7.4 Abordagem de avaliação

| Aspeto | Definição |
|---|---|
| Finalidade | Rascunho útil para o administrador rever, nunca documento final |
| Entradas | Assembleias simuladas, gravadas pela equipa a partir de guiões com decisões conhecidas (sem dados reais) |
| Casos difíceis | Ruído, vozes sobrepostas, sotaques, nomes próprios e valores monetários, decisões revogadas, prompt injection no áudio |
| Saídas esperadas | Ata de referência escrita pela equipa por guião |
| Medidas | % de decisões captadas, nº de informações inventadas por ata, taxa de erro de palavras |
| Critérios de aceitação | TODO |
| Latência | TODO: tempo máximo entre carregar o áudio e ter o rascunho |
| Custo | TODO: custo por hora de áudio do serviço escolhido |
| Limitações | Conjunto sintético e pequeno, falantes da equipa, sem assembleias reais |

### 7.5 Baseline e fallback
- **Baseline não-IA:** ata escrita manualmente (comparação de tempo e qualidade).
- **Fallback:** com a IA indisponível, o áudio fica guardado, a transcrição é repetida, o administrador é avisado (modo degradado, NFR-01) e pode publicar ata manual. A interface nunca apresenta conteúdo de IA como facto verificado (US-10).

---

## 8. Technical Design

---

## 9. Architecture Decision Records

---

## 10. Security and Privacy Assessment

### 10.1 Dados sensíveis

| Dado | Sensibilidade | Quem vê | Observações |
|---|---|---|---|
| Nome do residente (autodeclarado) | Pessoal | Administrador e o próprio; outros só por escolha do autor, num reporte | Único dado pessoal; não aparece em avisos, logs nem notificações a outros |
| Fração | Pessoal (indireto) | Administrador e o próprio | Nunca mostrada aos outros residentes |
| Reportes (texto e fotos) | Podem conter dados de terceiros | Todos | Aviso no formulário; remover metadados das fotos (ex.: localização). TODO (equipa): confirmar |
| Áudio e transcrição | Pessoal (voz, nomes) | Administrador; ata aprovada: residentes | Ver 7.3 |
| Credencial do dispositivo | Segredo | Dispositivo (servidor guarda só o hash) | |

### 10.2 Controlo de acessos

| Recurso | Residente | Administrador |
|---|---|---|
| Criar reporte | Sim (autor = identidade do dispositivo) | - |
| Ver reporte | Todos os do prédio, sem fração e com nome só se o autor optou (o próprio vê o seu) | Todos, com nome e fração |
| Mudar estado, remover identidade, revogar QR code | Não | Sim |
| Seguir um reporte | Sim (invisível aos outros residentes) | Vê só o nº de seguidores |
| Ver avisos e atas aprovadas | Sim | Sim |

Autorização verificada no servidor, com testes automáticos que confirmam que as respostas aos residentes nunca incluem fração nem nome do autor (salvo `mostrar_nome`). A autenticação do administrador pode ser mock no MVP, sem desativar controlos.

### 10.3 Minimização e finalidade (RGPD)
- Só se recolhe o **nome** (e a fração, vinda do QR code) para identificar o autor perante o administrador; finalidade indicada no ecrã (US-15). O nome só é mostrado aos outros por escolha do autor, reporte a reporte.
- Sem telefone, e-mail nem localização. Testes e demonstração com dados sintéticos.
- O residente pode corrigir o nome e pedir apagamento ao administrador (remoção da identidade).
- Base de licitude proposta: interesse legítimo do condomínio. TODO (equipa): validar com os docentes.

### 10.4 Retenção
- **Nome e credencial:** enquanto a identidade estiver ativa; apagados quando o administrador a remove.
- **Reportes de identidades removidas:** mantêm-se como "Residente removido" + fração. Áudio apagado após aprovação da ata. Prazo dos reportes e histórico: TODO (equipa).

### 10.5 QR code, revogação e abuso
- O QR code contém um token aleatório (só o hash fica guardado). Revogar/regenerar bloqueia novos acessos e mantém as identidades existentes; o administrador remove as que não reconheça.
- Criar identidades tem limite de tentativas e máximo por fração (proposta: 10). TODO (equipa): confirmar.

### 10.6 Modelo de ameaças inicial

| Ameaça | Mitigação |
|---|---|
| QR code divulgado a terceiros | Revogação/regeneração; revisão de identidades pelo administrador |
| Adivinhar tokens | Token aleatório longo; limite de tentativas |
| Personificação (mesmo nome) | Risco aceite como baixo: fração sempre registada; nome único por fração; remoção da identidade |
| Acesso indevido ao autor (IDOR) | Autorização no servidor: nome e fração só ao administrador e ao próprio (nome também com `mostrar_nome`); testes automáticos |
| Dados de terceiros em reportes visíveis a todos | Aviso no formulário; remoção de metadados; TODO (equipa): ocultar reporte pelo administrador |
| Roubo da credencial do dispositivo | Credencial opaca, só hash no servidor, comunicação cifrada, revogação ao remover identidade |
| Fila offline expõe dados no dispositivo | Dados mínimos na fila; envio recusado se a identidade foi removida |
| Nome em logs, avisos ou notificações | Logs com id da identidade; avisos sem reporter; testes automáticos |
| Prompt injection e dados pessoais no áudio | Ver 7.3 |

---

## 11. Walking Skeleton
