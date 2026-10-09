# Requisitos

> Este documento regista os requisitos (funcionais e não funcionais) do produto e o seu estado de validação ao longo do tempo. É referenciado a partir do [capítulo 4 do Sprint A](./sprintA/sprintA.md#4-rascunho-de-requisitos) e deve ser atualizado à medida que os requisitos são discutidos e validados com os clientes (docentes).

## Legenda de estado
- **Draft**: proposto pela equipa, ainda não discutido com os clientes.
- **In Review**: apresentado aos clientes (docentes), aguarda feedback/aprovação.
- **Approved**: validado pelos clientes (docentes) e pronto para ser detalhado em user stories no [Product Backlog](./sprintA/sprintA.md#6-product-backlog).

## Histórico de versões

| Versão | Data | Alterações |
|---|---|---|
| v0.1 | 2026-10-03 | Primeira lista de funcionalidades e requisitos não funcionais, elaborada pela equipa (rascunho inicial, ainda sem validação dos clientes). |
| v0.2 | 2026-10-08 | Adicionados RNF-06 (funcionamento sem internet) e RNF-07 (resiliência a serviços externos), derivados dos workflows de utilizador. Adicionado RF-09 (aviso ligado a um pedido). |

## Funcionalidades principais (por epic)

### Epic: Gestão de avarias

| ID | Funcionalidade | O que faz | Prioridade | Versão | Estado |
|---|---|---|---|---|---|
| RF-01 | Reportar problema | Foto + categoria + localização no prédio, em menos de 1 minuto | Essencial | v0.1 | Draft |
| RF-02 | Estado do pedido | Mostra se o pedido está reportado, em curso ou resolvido | Essencial | v0.1 | Draft |
| RF-03 | Histórico do prédio | Lista de pedidos abertos e fechados, visível a residentes e administrador | Essencial | v0.1 | Draft |
| RF-04 | Notificações de estado | Avisa quem reportou quando o estado muda | Essencial | v0.1 | Draft |
| RF-05 | Deteção de duplicados | Avisa se um novo pedido é parecido com um já existente | Desejável | v0.1 | Draft |

### Epic: Comunicação e governação do condomínio

| ID | Funcionalidade | O que faz | Prioridade | Versão | Estado |
|---|---|---|---|---|---|
| RF-06 | Mural digital de avisos | Substitui os posters e o "boca em boca" pós-assembleia | Importante | v0.1 | Draft |
| RF-07 | Calendário de atividades | Administrador agenda assembleias/atividades futuras; residentes recebem lembretes (ex.: convocatórias, atas) | Importante | v0.1 | Draft |
| RF-09 | Aviso ligado a um pedido | Administrador associa um aviso a um pedido específico (ex.: buraco grande no chão no local X) para alertar todos os residentes do risco, sem expor quem reportou nem os detalhes privados do pedido | Importante | v0.1 | Draft |

### Epic: Privacidade e confiança

| ID | Funcionalidade | O que faz | Prioridade | Versão | Estado |
|---|---|---|---|---|---|
| RF-08 | Visibilidade do pedido por assunto | Só quem é afetado vê o pedido; não é visível a todo o prédio | Importante | v0.1 | Draft |

## Requisitos não funcionais

| ID | Categoria | Requisito | O que significa | Versão | Estado |
|---|---|---|---|---|---|
| RNF-01 | Usabilidade | Rapidez | Reportar um problema demora menos de 1 minuto, mesmo com internet fraca | v0.1 | Draft |
| RNF-02 | Acessibilidade | Acessibilidade | Utilizável por pessoas com dificuldades de visão ou audição | v0.1 | Draft |
| RNF-03 | Privacidade | Minimização de dados | Dados pessoais guardados só o tempo necessário e não partilhados sem necessidade | v0.1 | Draft |
| RNF-04 | Segurança | Controlo de acesso | Só residentes do prédio (com código de acesso) entram na app; administrador tem permissões diferentes de residente | v0.1 | Draft |
| RNF-05 | Observabilidade | Monitorização | Registo de erros para a equipa perceber rapidamente se algo falha | v0.1 | Draft |
| RNF-06 | Resiliência | Funcionamento sem internet | Sem ligação, o que o utilizador cria no telemóvel (pedidos, reuniões, áudio de assembleias) fica guardado no dispositivo numa fila local e é enviado automaticamente quando a internet voltar, sem perda de dados | v0.1 | Draft |
| RNF-07 | Resiliência | Falha de serviços externos | Se um serviço externo falhar (ex.: calendário ou transcrição por IA), o sistema tenta um serviço alternativo quando existir, preserva os dados já recolhidos (ex.: o áudio fica guardado e a transcrição é repetida mais tarde) e informa o utilizador de que está em modo degradado | v0.1 | Draft |
