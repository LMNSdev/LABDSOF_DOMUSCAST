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
| v0.2 | 2026-10-08 | Adicionados RNF-06 (funcionamento sem internet) e RNF-07 (resiliência a serviços externos), derivados dos workflows de utilizador. Adicionado RF-09 (aviso ligado a um reporte). |
| v0.3 | 2026-10-10 | Identificação do residente pelo nome (RF-10, RF-11, RNF-08); reportes visíveis a todos com autor oculto por omissão (RF-03, RF-08); novos RF-12, RF-13 e RF-14; RF-01, RF-04, RNF-03, RNF-04 e RNF-06 atualizados. |

## Funcionalidades principais (por epic)

### Epic: Gestão de avarias

| ID | Funcionalidade | O que faz | Prioridade | Versão | Estado |
|---|---|---|---|---|---|
| RF-01 | Reportar problema | Descrição + foto opcional, em menos de 1 minuto; o reporte fica associado ao nome e à fração do autor (RF-10). TODO (equipa): decidir se categoria e localização no prédio entram no MVP | Essencial | v0.3 | Draft |
| RF-02 | Estado do reporte | Mostra se o reporte está reportado, em curso ou resolvido | Essencial | v0.1 | Draft |
| RF-03 | Histórico do prédio | Lista de reportes abertos e fechados, visível a todos os residentes e ao administrador, para acompanharem a resolução; o autor segue o RF-08 (oculto por omissão) | Essencial | v0.3 | Draft |
| RF-04 | Notificações de estado | Avisa quem reportou, e quem segue o reporte (RF-14), quando o estado muda (estado visível na lista de reportes; entrega push em US-11) | Importante | v0.3 | Draft |
| RF-05 | Deteção de duplicados | Avisa se um novo reporte é parecido com um já existente | Desejável | v0.1 | Draft |
| RF-13 | Tratamento de reportes duplicados | O administrador marca um reporte como duplicado de outro ("Reporte duplicado do #<id>"); o autor passa a acompanhar o original como co-reporter | Essencial | v0.3 | Draft |
| RF-14 | Seguir um reporte | Qualquer residente pode seguir um reporte para receber notificações do estado (autores e co-reporters seguem automaticamente); só o administrador vê o número de seguidores | Desejável | v0.3 | Draft |

### Epic: Comunicação e governação do condomínio

| ID | Funcionalidade | O que faz | Prioridade | Versão | Estado |
|---|---|---|---|---|---|
| RF-06 | Mural digital de avisos | Substitui os posters e o "boca em boca" pós-assembleia | Importante | v0.1 | Draft |
| RF-07 | Calendário de atividades | Administrador agenda assembleias/atividades futuras; residentes recebem lembretes (ex.: convocatórias, atas) | Importante | v0.1 | Draft |
| RF-09 | Aviso ligado a um problema | Administrador associa um aviso a um report de um problema específico (ex.: buraco grande no chão no local X) para alertar todos os residentes do risco | Importante | v0.1 | Draft |
| RF-12 | Indicador de progresso do prédio | Mostra o número agregado de reportes resolvidos face aos abertos (sem nomes, rankings nem comparações), ocultável pelo residente (mecanismo de engagement ético) | Desejável | v0.3 | Draft |

### Epic: Privacidade e confiança

| ID | Funcionalidade | O que faz | Prioridade | Versão | Estado |
|---|---|---|---|---|---|
| RF-08 | Visibilidade do reporte e privacidade do autor | Todos os residentes veem os reportes; o autor está oculto por omissão (só o administrador vê nome e fração) e pode escolher mostrar o nome num reporte | Importante | v0.3 | Draft |
| RF-10 | Identificação do residente pelo nome | Com um QR code partilhado pela fração, a app pede o nome (único na fração) no primeiro acesso, guarda a identidade no dispositivo, permite editar o nome e anexa-o a cada reporte para o administrador saber quem reportou | Essencial | v0.3 | Draft |
| RF-11 | Gestão de identidades e QR codes | O administrador vê as identidades por fração, remove uma identidade (ex.: saída da fração) e revoga/regenera o QR code de uma fração (ex.: QR code divulgado a terceiros) | Essencial | v0.3 | Draft |

## Requisitos não funcionais

| ID | Categoria | Requisito | O que significa | Versão | Estado |
|---|---|---|---|---|---|
| RNF-01 | Usabilidade | Rapidez | Reportar um problema demora menos de 1 minuto, mesmo com internet fraca | v0.1 | Draft |
| RNF-02 | Acessibilidade | Acessibilidade | Utilizável por pessoas com dificuldades de visão ou audição | v0.1 | Draft |
| RNF-03 | Privacidade | Minimização de dados | Dados pessoais guardados só o tempo necessário e não partilhados sem necessidade; só se recolhe o nome (para identificar o autor perante o administrador), sem telefone nem e-mail | v0.3 | Draft |
| RNF-04 | Segurança | Controlo de acesso | Só residentes do prédio (com QR code válido da sua fração) entram na app; o QR code usa um token não adivinhável e pode ser revogado; administrador tem permissões diferentes de residente | v0.3 | Draft |
| RNF-05 | Observabilidade | Monitorização | Registo de erros para a equipa perceber rapidamente se algo falha | v0.1 | Draft |
| RNF-06 | Resiliência | Funcionamento sem internet | Sem ligação, o que o utilizador cria no telemóvel (reportes, reuniões, áudio de assembleias) fica guardado no dispositivo numa fila local e é enviado automaticamente quando a internet voltar, sem perda de dados; os itens em fila mantêm o autor | v0.3 | Draft |
| RNF-07 | Resiliência | Falha de serviços externos | Se um serviço externo falhar (ex.: calendário ou transcrição por IA), o sistema tenta um serviço alternativo quando existir, preserva os dados já recolhidos (ex.: o áudio fica guardado e a transcrição é repetida mais tarde) e informa o utilizador de que está em modo degradado | v0.1 | Draft |
| RNF-08 | Privacidade | Identidade e retenção do nome | O nome só é visível ao administrador e ao próprio (e aos outros se o autor o mostrar num reporte), não aparece em logs nem avisos e é apagado quando a identidade é removida (o reporte fica como "Residente removido"); retenção dos reportes: TODO (equipa) | v0.3 | Draft |
