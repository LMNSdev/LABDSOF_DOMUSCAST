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

---

## 3. Investigação de Utilizadores

### Método

### Resultados

### Limitações

### Decisões de produto resultantes

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
