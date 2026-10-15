# Requisitos

> Requisitos funcionais e não funcionais do produto e o seu estado de validação ao longo do tempo. Referenciado a partir do [capítulo 4 do Sprint A](./sprintA/sprintA.md#4-rascunho-de-requisitos); atualizar à medida que os requisitos são validados com os docentes.

## Legenda de estado
- **Draft**: proposto pela equipa, ainda não discutido com os docentes.
- **In Review**: apresentado aos docentes, aguarda feedback.
- **Approved**: validado pelos docentes, pronto a detalhar em user stories no [Product Backlog](./backlog.md).

## Histórico de versões

| Versão | Data | Alterações |
|---|---|---|
| v0.1 | 2026-10-03 | Primeira lista de funcionalidades e requisitos não funcionais (rascunho da equipa). |
| v0.2 | 2026-10-08 | RNF-06 (sem internet) e RNF-07 (resiliência a serviços externos), derivados dos workflows; RF-09 (aviso ligado a um reporte). |
| v0.3 | 2026-10-10 | Identificação pelo nome (RF-10, RF-11, RNF-08); reportes visíveis a todos com autor oculto por omissão (RF-03, RF-08); novos RF-12, RF-13, RF-14; RF-01, RF-04, RNF-03, RNF-04 e RNF-06 atualizados. |
| v0.4 | 2026-10-15 | RF-02 passa a "Aberto" (alinhado com US-02 e o modelo de dados); RF-04 sem fornecedor de push. |

## Funcionalidades principais (por epic)

### Epic: Gestão de avarias

| ID | Funcionalidade | O que faz | Prioridade | Versão | Estado |
|---|---|---|---|---|---|
| RF-01 | Reportar problema | Descrição + foto opcional, em menos de 1 minuto; ligado ao nome e fração do autor (RF-10). TODO (equipa): categoria e localização no MVP? | Essencial | v0.3 | Draft |
| RF-02 | Estado do reporte | Aberto, em curso ou resolvido | Essencial | v0.4 | Draft |
| RF-03 | Histórico do prédio | Lista de reportes abertos e fechados, visível a todos os residentes e ao administrador; autor segue RF-08 | Essencial | v0.3 | Draft |
| RF-04 | Notificações de estado | Avisa quem reportou e quem segue (RF-14) quando o estado muda (estado na lista; notificação local em US-11) | Importante | v0.4 | Draft |
| RF-05 | Deteção de duplicados | Avisa se um novo reporte é parecido com um existente | Desejável | v0.1 | Draft |
| RF-13 | Tratamento de duplicados | O administrador marca um reporte como "Reporte duplicado do #<id>"; o autor passa a co-reporter do original | Essencial | v0.3 | Draft |
| RF-14 | Seguir um reporte | Qualquer residente segue um reporte para receber notificações (autores e co-reporters seguem automaticamente); só o administrador vê o nº de seguidores | Desejável | v0.3 | Draft |

### Epic: Comunicação e governação do condomínio

| ID | Funcionalidade | O que faz | Prioridade | Versão | Estado |
|---|---|---|---|---|---|
| RF-06 | Mural digital de avisos | Substitui os posters e o "boca em boca" pós-assembleia | Importante | v0.1 | Draft |
| RF-07 | Calendário de atividades | O administrador agenda assembleias/atividades; residentes recebem lembretes (convocatórias, atas) | Importante | v0.1 | Draft |
| RF-09 | Aviso ligado a um problema | Aviso associado a um reporte (ex.: buraco no chão no local X) para alertar todos do risco | Importante | v0.1 | Draft |
| RF-12 | Indicador de progresso do prédio | Número agregado de resolvidos vs abertos (sem nomes, rankings nem comparações), ocultável (engagement ético) | Desejável | v0.3 | Draft |

### Epic: Privacidade e confiança

| ID | Funcionalidade | O que faz | Prioridade | Versão | Estado |
|---|---|---|---|---|---|
| RF-08 | Visibilidade do reporte e privacidade do autor | Todos veem os reportes; autor oculto por omissão (só o administrador vê nome e fração); o autor pode mostrar o nome num reporte | Importante | v0.3 | Draft |
| RF-10 | Identificação pelo nome | Com QR code partilhado pela fração, a app pede o nome (único na fração) no primeiro acesso, guarda a identidade no dispositivo, permite editar e anexa-o a cada reporte | Essencial | v0.3 | Draft |
| RF-11 | Gestão de identidades e QR codes | O administrador vê as identidades por fração, remove uma identidade (ex.: saída da fração) e revoga/regenera o QR code (ex.: divulgado a terceiros) | Essencial | v0.3 | Draft |

## Requisitos não funcionais

| ID | Categoria | Requisito | O que significa | Versão | Estado |
|---|---|---|---|---|---|
| RNF-01 | Usabilidade | Rapidez | Reportar demora menos de 1 minuto, mesmo com internet fraca | v0.1 | Draft |
| RNF-02 | Acessibilidade | Acessibilidade | Utilizável por pessoas com dificuldades de visão ou audição | v0.1 | Draft |
| RNF-03 | Privacidade | Minimização de dados | Dados pessoais guardados só o tempo necessário e não partilhados sem necessidade; só se recolhe o nome, sem telefone nem e-mail | v0.3 | Draft |
| RNF-04 | Segurança | Controlo de acesso | Só residentes com QR code válido da sua fração entram; token não adivinhável e revogável; administrador com permissões diferentes | v0.3 | Draft |
| RNF-05 | Observabilidade | Monitorização | Registo de erros para a equipa perceber rapidamente falhas | v0.1 | Draft |
| RNF-06 | Resiliência | Funcionamento sem internet | O que o utilizador cria (reportes, reuniões, áudio) fica em fila local e é enviado automaticamente quando a internet voltar, sem perda; os itens mantêm o autor | v0.3 | Draft |
| RNF-07 | Resiliência | Falha de serviços externos | Se um serviço externo falhar (calendário, IA), tenta alternativa quando existir, preserva os dados (ex.: áudio guardado, transcrição repetida) e informa que está em modo degradado | v0.1 | Draft |
| RNF-08 | Privacidade | Identidade e retenção do nome | Nome visível só ao administrador e ao próprio (e aos outros se o autor o mostrar), nunca em logs nem avisos; apagado ao remover a identidade ("Residente removido"); retenção dos reportes: TODO (equipa) | v0.3 | Draft |
