# Product Backlog

> Este documento é o **Product Backlog** vivo do produto, a lista completa e priorizada de tudo o que o produto pode vir a ter. É diferente do **Sprint Backlog** (ex.: [Sprint B Backlog](./sprintB/backlog.md)), que é apenas o subconjunto de itens que a equipa se compromete a entregar num sprint específico, depois de cada item passar na Definition of Ready, e vive na pasta do respetivo sprint. É referenciado a partir do [capítulo 6 do Sprint A](./sprintA/sprintA.md#6-product-backlog).

## Legenda

>**Prioridade (MoSCoW):** **M**ust have, **S**hould have, **C**ould have, **W**on't have (nesta iteração). Pontos em série de Fibonacci (1, 2, 3, 5, 8, 13).

>**Estado de validação:** Draft (proposto pela equipa), In Review (apresentado aos clientes/docentes, aguarda feedback), Approved (validado pelos clientes).

## Histórico de versões

| Versão | Data | Alterações |
|---|---|---|
| v0.1 | 2026-10-03 | Product Backlog inicial priorizado pela equipa (Draft), ainda sem validação dos clientes (docentes). |

## 1. Product Backlog

| ID | User Story | Prioridade | Pontos | Estado | Critérios de aceitação |
|---|---|---|---|---|---|
| US-01 | Como **administrador**, quero criar a conta do condomínio e gerar um QR code por fração, para que cada residente possa associar a sua conta em segundos. | M | 5 | Draft | - [ ] Administrador consegue criar o condomínio com nome e nº de frações.<br>- [ ] É gerado um QR code único por fração.<br>- [ ] O scan do QR code associa o residente à fração correta, sem necessitar de partilhar contacto pessoal.<br>- [ ] Um QR code já associado não pode ser reutilizado por outro residente. |
| US-02 | Como **residente**, quero reportar uma avaria com foto e descrição, para que o administrador saiba do problema sem precisar de o contactar diretamente. | M | 5 | Draft | - [ ] Formulário permite descrição (texto) e, opcionalmente, uma foto.<br>- [ ] O pedido fica visível apenas ao administrador e ao autor, não a todo o condomínio.<br>- [ ] O pedido criado fica com estado inicial "Aberto".<br>- [ ] O residente recebe confirmação de que o pedido foi submetido. |
| US-03 | Como **residente**, quero consultar o estado do meu pedido, para saber se já está a ser tratado sem ter de perguntar ao administrador. | M | 3 | Draft | - [ ] A lista de pedidos do residente mostra o estado atual (Aberto/Em curso/Resolvido).<br>- [ ] Cada pedido mostra a data de criação e da última atualização.<br>- [ ] O estado atualiza automaticamente quando o administrador o altera. |
| US-04 | Como **administrador**, quero ver todos os pedidos do condomínio numa lista única, para priorizar e evitar duplicados. | M | 5 | Draft | - [ ] A lista mostra todos os pedidos com estado, data e fração de origem.<br>- [ ] A lista pode ser filtrada por estado.<br>- [ ] Pedidos semelhantes reportados por vários residentes são visualmente agrupados ou sinalizados. |
| US-05 | Como **administrador**, quero mudar o estado de um pedido (Aberto → Em curso → Resolvido) e adicionar uma nota, para manter um histórico auditável de diligência. | M | 5 | Draft | - [ ] A mudança de estado fica registada com data/hora e autor.<br>- [ ] O histórico de alterações de um pedido é consultável e não pode ser apagado.<br>- [ ] O residente autor do pedido é notificado da mudança de estado. |
| US-06 | Como **administrador**, quero publicar um aviso geral (ex.: corte de água, assembleia), para que chegue a todos os residentes sem depender de posters físicos. | S | 3 | Draft | - [ ] O aviso é visível a todos os residentes do condomínio.<br>- [ ] O aviso tem título, texto e data de publicação.<br>- [ ] Os residentes veem os avisos mais recentes primeiro. |
| US-07 | Como **residente**, quero consultar o quadro de avisos do condomínio, para me manter informado mesmo que esteja ausente. | S | 2 | Draft | - [ ] O quadro de avisos é acessível a partir do ecrã principal.<br>- [ ] Os avisos antigos permanecem consultáveis (histórico). |
| US-08 | Como **residente com necessidades de acessibilidade**, quero que o reporte de avarias seja utilizável com leitor de ecrã e sem depender só de som, para não ficar excluído da app. | S | 3 | Draft | - [ ] Os elementos principais têm texto alternativo/rótulos acessíveis.<br>- [ ] As fotos de avarias têm campo de descrição alternativa.<br>- [ ] As notificações de estado têm alternativa não sonora (visual). |
| US-09 | Como **residente**, quero que o meu número de telefone e dados pessoais não sejam visíveis a outros residentes, para preservar a minha privacidade. | M | 3 | Draft | - [ ] Nenhum residente consegue ver o contacto pessoal de outro residente na app.<br>- [ ] Apenas o essencial (ex.: fração) é guardado por residente, sem perfil completo.<br>- [ ] Os dados de um residente removido deixam de ser acessíveis após remoção da conta. |
| US-10 | Como **administrador**, quero carregar o áudio de uma assembleia e obter automaticamente uma transcrição/rascunho de ata, para não ter de a escrever manualmente e garantir que fica acessível a quem faltou (capacidade assistida por IA). | S | 5 | Draft | - [ ] O administrador consegue carregar um ficheiro de áudio associado a uma reunião/assembleia.<br>- [ ] O sistema gera uma transcrição/rascunho de ata a partir do áudio.<br>- [ ] O rascunho gerado é claramente identificado como conteúdo gerado por IA, pendente de revisão e aprovação do administrador antes de ser publicado aos residentes.<br>- [ ] Quando o serviço de transcrição está indisponível, o administrador consegue ainda assim publicar uma ata escrita manualmente (fallback não-IA). |
| US-11 | Como **residente**, quero receber uma notificação quando o meu pedido muda de estado, para não ter de verificar manualmente a app. | C | 3 | Draft | - [ ] A notificação é enviada na mudança de estado do pedido.<br>- [ ] O residente pode consultar o pedido diretamente a partir da notificação. |
| US-12 | Como **membro da comissão de condóminos**, quero consultar um histórico/relatório dos pedidos resolvidos, para validar a diligência do administrador. | C | 3 | Draft | - [ ] A comissão tem acesso de leitura ao histórico de pedidos e ao seu estado.<br>- [ ] O relatório pode ser filtrado por período. |
| US-13 | Como **residente**, quero ver no calendário as reuniões/assembleias do condomínio e receber uma notificação de lembrete antes de cada uma, para não as esquecer nem ficar de fora de decisões importantes (integração com sistema de calendário externo). | S | 3 | Draft | - [ ] O administrador consegue agendar uma reunião/assembleia com data, hora e local.<br>- [ ] A reunião agendada é sincronizada com um serviço de calendário externo (ex.: Google Calendar/iCal) ou um simulador realista.<br>- [ ] O residente recebe uma notificação de lembrete antes da reunião (ex.: 24h antes).<br>- [ ] Quando o serviço de calendário externo está indisponível ou devolve dados inválidos, a reunião continua visível na app a partir dos dados guardados localmente. |
| NFR-01 | Como **equipa de produto**, quero que a app continue a funcionar de forma degradada quando um componente externo (transcrição de atas por IA ou serviço de calendário) está indisponível, para que o residente consiga sempre reportar/acompanhar avarias e ver as reuniões agendadas (cenário de degradação). | M | 3 | Draft | - [ ] Os fallbacks já definidos em US-10 (ata manual) e US-13 (dados locais) funcionam de facto quando o respetivo serviço externo está em baixo.<br>- [ ] A app comunica ao utilizador, de forma clara e visível, que está a operar em modo degradado, em vez de falhar silenciosamente.<br>- [ ] Cada indisponibilidade fica registada nos logs/observabilidade da equipa, com timestamp e componente afetado. |

**Fora do âmbito desta iteração (Won't have):** contabilidade/quotas, gestão financeira, votações formais em assembleia, integração com fornecedores externos de manutenção, suporte multi-prédio para o mesmo administrador.

## 2. Plano de release inicial (visão multi-sprint)

| Sprint | Entregável funcional | User Stories incluídas |
|---|---|---|
| Sprint A | Esqueleto de ponta a ponta (sem UI/lógica completas) | US-01, US-02 (versão mínima) |
| Sprint B | Fatia vertical operacional: reportar avaria -> análise -> resolução, com privacidade por desenho, 1ª versão da transcrição de atas por IA (com fallback manual: ata escrita à mão), 1ª integração externa (calendário de reuniões/assembleias) e demonstração de 1 condição de falha | US-01, US-02, US-03, US-04, US-05, US-09, US-10, US-13, NFR-01 |
| Sprint C | Produto robustecido e avaliado: avisos, acessibilidade, notificações, relatório da comissão, avaliação formal da IA e do cenário de degradação | US-06, US-07, US-08, US-11, US-12 |

## 2. MVP
A versão mínima viável (MVP) corresponde ao conjunto de histórias "Must have", que materializam a [proposta de valor](./sprintA/sprintA.md#2-análise-de-mercado-e-concorrência) definida no capítulo 2 do Sprint A: transformar o reporte de avarias disperso em pedidos com estado, dono e histórico, com privacidade por desenho. As histórias US-10 (transcrição de atas por IA) e US-13 (calendário de reuniões), embora "Should have", têm de estar presentes já no Sprint B porque o enunciado exige uma primeira versão da capacidade de IA e uma primeira integração externa nesse sprint (não apenas no Sprint C).
