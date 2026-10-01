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

### Controlo de versões (Git) - GitHub Flow

### Gestão de issues

### Definition of Ready (DoR)

### Definition of Done (DoD)

### Papéis da equipa

---

## 1. Relatório de Problema e Oportunidade

### Comunidade-alvo

### Problema

### Mapa de stakeholders

### Evidência do problema

### Pressupostos e riscos

---

## 2. Análise de Mercado e Concorrência

TODO: Adicionar dados/fontes/evidências concretas do texto segundo a pesquisa realisada

*Método: revisão dos sites oficiais dos principais produtos (setembro 2026) + observação direta do statu quo. Os dados de lojas de apps e datas de lançamento indicados abaixo devem ser validados antes da entrega final.*

**Achado da pesquisa de trabalhos relacionados:** as soluções digitais de gestão de condomínio existentes (ex.: TownSq, Condo Control, Buildium a nível internacional; Gecond, SolidSoft GC, GOcondomínios em Portugal) são construídas à volta da **gestão de dinheiro** (quotas, contabilidade, pagamentos, orçamentos) e da **governança** (votações, atas), não da **gestão de problemas/informação** do dia a dia (reportar e acompanhar uma avaria, por exemplo). É esse o espaço que a nossa app ocupa.

### 2.1 Alternativas e status quo

#### Soluções ad-hoc (WhatsApp/Messenger, posters, folha de papel)
- **Funcionalidades principais:** mensagens instantâneas em grupo, posters físicos no elevador/hall, folha de papel para avarias.
- **Pontos fortes:** adoção imediata (quase todos têm WhatsApp), custo zero, comunicação em tempo real, acessível a residentes não-digitais (papel).
- **Pontos fracos:** perda de mensagens importantes no meio de conversas não relacionadas; ausência de acompanhamento de estado (tickets repetidos); falta de histórico auditável para comprovar a diligência do administrador; editais em papel ficam desatualizados, caem ou estragam-se, e não chegam a quem está ausente (proprietários ausentes, inquilinos que não passam pelo hall).
- **Modelo de negócio/sustentabilidade:** N/A (ferramentas genéricas gratuitas).
- **UX:** familiar e intuitiva para conversas sociais, mas caótica e frustrante para a gestão e triagem de problemas.
- **Privacidade e confiança:** baixa; os números de telefone pessoais de todos os moradores ficam expostos a todo o grupo.
- **Diferenciação:** estruturar o que hoje é conversa em pedidos com estado, dono e histórico, sem sacrificar a simplicidade do chat.

#### Software de gestão profissional de condomínios
- **Funcionalidades principais:** faturação, emissão de recibos e avisos de cobrança, gestão de contas correntes, redação formal de atas, gestão de ocorrências (focada no backoffice).
- **Pontos fortes:** altamente robustos do ponto de vista legal e financeiro; centralizam toda a documentação.
- **Pontos fracos:** demasiado complexos e com funcionalidades excessivas para um administrador voluntário; pouco focados na comunicação direta e na comunidade; não resolvem o atrito do utilizador final em reportar pequenos problemas do dia a dia; onboarding e preço pesados para 1 prédio autogerido.
- **Modelo de negócio:** SaaS B2B com subscrições mensais ou anuais muitas vezes avultadas e dependentes do número de frações geridas.
- **UX:** interface utilitária e corporativa, com curva de aprendizagem íngreme para leigos.
- **Privacidade e confiança:** elevada, com controlo de acessos rigoroso e conformidade com o RGPD estabelecida.

#### Plataformas comunitárias genéricas (redes sociais de vizinhança)
- **Funcionalidades principais:** feed de notícias social, recomendações de serviços locais, alertas de segurança e mensagens privadas.
- **Pontos fortes:** promovem o sentido de vizinhança; úteis para encontrar prestadores de serviços locais (canalizadores, eletricistas).
- **Pontos fracos:** não oferecem hierarquia de edifício (propriedade horizontal) nem ferramentas estruturadas de gestão de avarias (tickets/estados); não há a figura do "Administrador" com permissões de gestão do prédio.
- **Modelo de negócio:** gratuito para o utilizador, sustentado por publicidade geolocalizada e patrocínios de negócios locais.
- **UX:** desenhada para potenciar o engajamento social (scroll infinito) e não para a resolução objetiva de tarefas.
- **Privacidade e confiança:** moderada a baixa; depende de políticas de partilha de dados com anunciantes e a verificação de moradas é por vezes falível.

#### Software de tickets de manutenção (ex.: UpKeep, Fixflo)
- **Para quem é:** facility managers, operadores imobiliários comerciais, senhorios profissionais.
- **Pontos fortes:** SLA rigoroso, despacho de fornecedores, manutenção preventiva.
- **Pontos fracos:** sem dimensão comunitária (sem quadro de avisos/visibilidade coletiva); exige criação de conta e input técnico detalhado só para reportar, por exemplo, uma lâmpada fundida.

### 2.2 Concorrentes digitais no mercado português

#### Gecond — "o meu condomínio"
- **Utilizadores-alvo:** condóminos, mas só é disponibilizada por convite, através de administrações que já usam o software Gecond; pressupõe uma administração (frequentemente profissional) já cliente do backend.
- **Funcionalidades:** votação antecipada em assembleias, registo e acompanhamento de avarias.
- **Pontos fracos:** avaliação muito baixa nas lojas de apps (1,7/5); depende de um terceiro (a administração) ter comprado o software primeiro, pelo que um administrador voluntário não o pode adotar sozinho.
- **Modelo:** B2B2C (vendido à empresa/administrador, não ao condomínio diretamente).

#### SolidSoft GC
- **Utilizadores-alvo:** dupla vertente, condóminos e técnicos de manutenção externos.
- **Funcionalidades:** gestão documental, pagamentos, contas correntes, ocorrências (reporte de avarias com foto e registo offline), assembleias com ata para download e assembleia digital por videoconferência.
- **Pontos fortes:** muito completo.
- **Pontos fracos:** a complexidade e amplitude (financeiro completo, rotas de manutenção) sugerem um produto pensado para administração profissional ou condomínios grandes, não para o administrador voluntário de um prédio de 10 frações.

#### My LDC (Loja do Condomínio)
- **Funcionalidades:** gratuita, com foco na relação administrador–condómino: consulta de informação do condomínio, pedidos e acesso à referência MB para pagamento, com o objetivo declarado de reforçar transparência e envolvimento.
- **Observações:** é o mais próximo conceptualmente da nossa proposta, mas é de 2017 e não há sinal de evolução recente; possível "produto abandonado" **(a validar)**.

#### GCondomPro
- Software de condomínios "original desde 1998", desktop, focado em documentos de cobrança e contas; geração anterior, pensado para administração financeira, não para coordenação do dia a dia entre vizinhos.

#### GOcondomínios (Sopenfor)
- Aplicação web de gestão de condomínios, sem instalação, com período de teste gratuito de 30 dias, de uma empresa com quase 30 anos no setor.
- **Modelo:** SaaS clássico B2B vendido a quem administra (empresa ou administrador), focado em ferramentas de gestão administrativa/financeira, não em comunicação estruturada entre residentes.

#### Unitify
- **Proposta:** plataforma "smart building" que liga controlo de acesso, intercomunicadores de vídeo, contadores inteligentes e uma app de residente num único sistema, com cobrança de quotas organizada por fração.
- **Modelo de negócio:** pagamentos via Multibanco e MB WAY, canais que os proprietários portugueses já usam para pagamentos recorrentes, mais integração Stripe para cartão.
- **Pontos fortes:** UX moderna, forte foco em Portugal (não é adaptação de produto brasileiro), pipeline de conteúdo/marketing ativo.
- **Pontos fracos para o nosso segmento:** desenhado para empresas de administração de condomínios e novos empreendimentos com sistemas prediais smart; pressupõe investimento em hardware (intercomunicadores, controlo de acesso) que um condomínio autogerido de 8-60 frações dificilmente vai financiar só para resolver "a luz da escada fundiu".

### 2.3 Referências internacionais
TownSq, Condo Control e Buildium são plataformas maduras de contabilidade, quotas, pagamentos e governança, dirigidas a administradores profissionais e gestoras de portefólios. Servem como referência de funcionalidades, mas não são concorrentes diretos no mercado português.

### 2.4 Quadro comparativo

| Alternativa | Para quem é | Força | Fraqueza (para o nosso alvo) |
|---|---|---|---|
| **Grupos WhatsApp/Messenger** | Qualquer grupo, sem configuração | Grátis, universal, zero fricção | Sem estado do pedido, sem privacidade, informação perde-se |
| **Media física** (avisos em papel, folhetos no elevador) | Residentes presenciais no prédio | Acessível a residentes não-digitais, sem exigir smartphone | Desatualiza-se, cai ou estraga-se; não chega a proprietários ausentes nem a inquilinos que não passam pelo hall |
| **Software de gestão profissional** (GOcondomínios, GCondomPro, SolidSoft GC; internacionais: TownSq, Condo Control, Buildium) | Administradores profissionais / gestoras de portefólios | Contabilidade, quotas, pagamentos e governança maduros; robustez legal | Foco em dinheiro/governança, não em problemas do dia a dia; complexidade e preço pesados para 1 prédio autogerido |
| **Apps de condóminos dependentes da administração** (Gecond) | Condóminos de prédios com administração cliente | Votação antecipada, registo de avarias | Só por convite; B2B2C; avaliação 1,7/5; inacessível a administrador voluntário |
| **My LDC** | Administrador–condómino | Gratuita, transparência, referência MB | Lançada em 2017, possível abandono (a validar) |
| **Smart building** (Unitify) | Administradoras e novos empreendimentos | UX moderna, MB WAY/Multibanco, foco em Portugal | Exige hardware e investimento inicial |
| **Software de tickets de manutenção** (UpKeep, Fixflo) | Facility managers, senhorios profissionais | SLA rigoroso, despacho de fornecedores, manutenção preventiva | Sem dimensão comunitária; exige conta e input técnico para reportar uma lâmpada fundida |
| **Plataformas comunitárias genéricas** | Vizinhança em geral | Sentido de vizinhança, recomendação de prestadores | Sem hierarquia de edifício nem tickets/estados; sem figura de administrador; modelo assente em publicidade |

### 2.5 Conclusão e oportunidade de diferenciação

Não existe, no mercado português, um produto pensado de raiz para o administrador voluntário de um condomínio pequeno/médio autogerido. Todos os concorrentes diretos assumem uma administração profissional já cliente (Gecond), um pacote de gestão financeira completo e pesado (SolidSoft, GOcondomínios), ou investimento em hardware smart (Unitify). O WhatsApp continua a ganhar por defeito, não porque seja bom, mas porque é a única opção com fricção zero.

**Diferenciação:**
1. Foco em gestão de problemas/informação, não em gestão de dinheiro: sem contabilidade, votações ou preços por portefólio.
2. Foco no residente, não no gestor: reportar em segundos é o ecrã principal, não uma funcionalidade escondida.
3. Zero-configuração para um único prédio autogerido, adotável por um administrador voluntário sem depender de terceiros.
4. Privacidade por desenho: visibilidade limitada aos residentes/administrador relevantes, sem expor números de telefone nem difundir tudo a todos.
5. Estrutura sem perder simplicidade: converter conversa em pedidos com estado, dono e histórico.
6. Baixo custo e sem hardware, adequado a prédios sem orçamento de gestão profissional.

---

## 3. Investigação de Utilizadores

### Método

A investigação combina três fontes complementares:

1. **Inquérito online** (Google Forms, distribuído pela rede da equipa e em grupos de Facebook/Reddit de moradores portugueses) — ver questionário abaixo.

2. **Leitura de reviews de apps concorrentes** nas lojas Google Play e App Store (foco: Gecond — "o meu condomínio", SolidSoft GC, My LDC), recolhendo padrões de queixas e elogios recorrentes.

3. **Observação informal** — os quatro membros da equipa habitam ou têm familiares em prédios autogeridos em Portugal; as situações descritas foram observadas diretamente (grupos de WhatsApp saturados, posters rasgados no elevador, administrador contactado por SMS ou chamada pessoal).

### Questionário

**Secção A — Perfil**
1. Qual é o seu papel no condomínio? *(Proprietário residente / Inquilino / Administrador / Outro)*
2. Quantas frações tem o seu prédio aproximadamente? *(Menos de 8 / 8–30 / 31–60 / Mais de 60)*
3. O seu prédio tem administração profissional ou é autogerido por um condómino eleito? *(Profissional / Condómino voluntário / Não sei)*

**Secção B — Comunicação atual**

4. Como comunica habitualmente avarias ou problemas do prédio? *(Grupo de WhatsApp/Messenger / Poster/aviso físico no prédio / Contacto direto com o administrador / E-mail / App dedicada / Outro)*
5. Com que frequência reporta um problema no prédio? *(Nunca / Raramente (1–2x/ano) / Às vezes (3–6x/ano) / Frequentemente (>6x/ano))*
6. Depois de reportar um problema, costuma saber se foi resolvido? *(Sim, sou sempre informado/a / Às vezes / Raramente / Nunca)*

**Secção C — Frustrações (escala 1 = nada frustrado, 5 = muito frustrado)**

7. "As minhas mensagens perdem-se no meio de outras conversas no grupo."
8. "Não sei se o problema que reportei já foi ou vai ser tratado."
9. "O mesmo problema é reportado várias vezes por pessoas diferentes."
10. "Não fui avisado/a sobre decisões ou assembleias do condomínio."
11. "O meu número de telefone pessoal fica exposto a todos os membros do grupo."
12. "Os avisos em papel no elevador/hall estão desatualizados ou em mau estado."

**Secção D — Adoção de nova ferramenta**

13. Usaria uma app dedicada ao seu condomínio para reportar avarias e ver avisos? *(Sim, definitivamente / Provavelmente sim / Provavelmente não / Definitivamente não)*
14. O que seria mais importante para decidir usar essa app? *(Ser rápida de usar / Privacidade dos meus dados / Gratuita ou barata / Que os vizinhos também a usassem / Outro)*
15. O que mais o/a inibiria de adotar uma app dessas? *(Mais uma app para instalar / Os vizinhos mais velhos não vão usar / Preocupações com privacidade / Já o WhatsApp chega / Outro)*
16. Quanto estaria disposto/a a pagar por fração, por mês, por um serviço sem publicidade e com privacidade garantida? *(Nada / Até 0,50 € / Até 1 € / Até 2 € / Mais de 2 €)*

**Secção E — Questão aberta**

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
