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
Moradores de prédios de habitação multifamiliar autogeridos em Portugal (regime de propriedade horizontal), tipicamente entre 8 e 60 frações, com administrador eleito de entre os condóminos (não uma empresa profissional de gestão).

**Utilizadores primários:** condóminos (proprietários e inquilinos) e o administrador do condomínio.

**Beneficiários secundários:** comissão de condóminos, prestadores de manutenção (canalizador, eletricista, elevadores), porteiro/funcionário (quando existe).

### Problema
Os condomínios coordenam problemas do edifício (fuga de água, luz da escada fundida, elevador avariado, etc.) normalmente através de um grupo de WhatsApp ou posters espalhados pelo prédio. No entanto, esta gestão traz alguns problemas:
- Mensagens perdem-se no meio de conversa não relacionada;
- Não há estado do pedido, pedidos repetidos e incerteza sobre se algo já foi tratado;
- Sem histórico auditável para o administrador (prioridades, prova de diligência na resolução);
- Quem gere o grupo é normalmente um voluntário sem ferramentas de apoio;
- Os posters junto ao elevador ficam desatualizados, são removidos ou simplesmente não chegam a inquilinos/residentes que raramente passam por ali;
- Decisões tomadas em assembleias de condóminos não chegam a quem falta (por doença, viagem, horário), a informação passa "de boca em boca" e é frequentemente distorcida ou incompleta, sem ata acessível e centralizada;
- Privacidade fraca nos grupos de WhatsApp: os números de telefone pessoais de todos os moradores ficam expostos a todo o grupo.

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

---

## 2. Análise de Mercado e Concorrência

### 2.1 Alternativas e statu quo

#### Soluções ad-hoc (WhatsApp/Messenger, posters, folha de papel)

#### Software de gestão profissional de condomínios

#### Plataformas comunitárias genéricas (redes sociais de vizinhança)

#### Software de tickets de manutenção (ex.: UpKeep, Fixflo)

### 2.2 Concorrentes digitais no mercado português

#### Gecond — "o meu condomínio"

#### SolidSoft GC

#### My LDC (Loja do Condomínio)

#### GCondomPro

#### GOcondomínios (Sopenfor)

#### Unitify

### 2.3 Referências internacionais

### 2.4 Quadro comparativo

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
