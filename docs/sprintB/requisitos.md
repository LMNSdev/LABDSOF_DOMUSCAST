# Requisitos

> Requisitos funcionais e não funcionais do produto e o seu estado de validação ao longo do tempo. Atualizar à medida que os requisitos são validados com os docentes.

## Legenda de estado
- **Draft**: proposto pela equipa, ainda não discutido com os docentes.
- **In Review**: apresentado aos docentes, aguarda feedback.
- **Approved**: validado pelos docentes, pronto a detalhar em user stories no [Product Backlog](./backlog.md).

## Histórico de versões

| Versão | Data | Alterações |
|---|---|---|
| v0.1 | 2026-10-30 | Primeira lista de funcionalidades e requisitos não funcionais do Sprint B. |

## Funcionalidades principais (por epic)

### Epic: Gestão de avarias

| ID | Funcionalidade | O que faz | Prioridade | Versão | Estado |
|---|---|---|---|---|---|
| RF-01 | Reportar problema | Descrição + foto opcional, em menos de 1 minuto; ligado ao nome e fração do autor (RF-10). Sem categoria nem localização no MVP: a descrição chega e evita recolher mais dados (RNF-03) | Essencial | v0.6 | Draft |
| RF-02 | Estado do reporte | Aberto, em curso ou resolvido | Essencial | v0.4 | Draft |
| RF-03 | Histórico do prédio | Lista de reportes abertos e fechados, visível a todos os residentes e ao administrador; autor segue RF-08 | Essencial | v0.3 | Draft |
| RF-04 | Notificações | Avisa quem reportou e quem segue (RF-14) quando o estado muda, e todos os residentes quando há um aviso novo ou uma ata aprovada (estado na lista; notificação local em US-11 e US-34) | Importante | v0.5 | Draft |
| RF-05 | Deteção de duplicados | Avisa se um novo reporte é parecido com um existente | Desejável | v0.1 | Draft |
| RF-13 | Tratamento de duplicados | O administrador marca um reporte como "Reporte duplicado do #<id>"; o autor passa a co-reporter do original | Essencial | v0.3 | Draft |
| RF-14 | Seguir um reporte | Qualquer residente segue um reporte para receber notificações (autores e co-reporters seguem automaticamente); só o administrador vê o nº de seguidores | Desejável | v0.3 | Draft |
| RF-16 | Ocultar reporte | O administrador oculta (e repoe) um reporte, por exemplo com dados de terceiros; deixa de aparecer aos residentes e a ação fica no histórico | Importante | v0.5 | Draft |

### Epic: Comunicação e governação do condomínio

| ID | Funcionalidade | O que faz | Prioridade | Versão | Estado |
|---|---|---|---|---|---|
| RF-06 | Mural digital de avisos | Substitui os posters e o "boca em boca" pós-assembleia; um aviso novo gera notificação local a todos os residentes | Importante | v0.5 | Draft |
| RF-07 | Calendário de atividades | O administrador agenda assembleias/atividades; residentes recebem lembretes (convocatórias, atas) e subscrevem o feed iCal do condomínio, protegido por um token que o administrador pode regenerar | Importante | v0.5 | Draft |
| RF-09 | Aviso ligado a um problema | Aviso associado a um reporte (ex.: buraco no chão no local X) para alertar todos do risco | Importante | v0.1 | Draft |
| RF-12 | Indicador de progresso do prédio | Número agregado de resolvidos vs abertos (sem nomes, rankings nem comparações), ocultável (engagement ético) | Desejável | v0.3 | Draft |
| RF-17 | Ata assistida por IA | O administrador carrega o áudio da assembleia e recebe transcrição e rascunho de ata, marcado como gerado por IA; só se publica após revisão e aprovação; com a IA indisponível, o áudio fica guardado e a ata pode ser escrita à mão | Importante | v0.5 | Draft |

### Epic: Privacidade e confiança

| ID | Funcionalidade | O que faz | Prioridade | Versão | Estado |
|---|---|---|---|---|---|
| RF-08 | Visibilidade do reporte e privacidade do autor | Todos veem os reportes; autor oculto por omissão (só o administrador vê nome e fração); o autor pode mostrar o nome num reporte | Importante | v0.3 | Draft |
| RF-10 | Identificação pelo nome | Com QR code partilhado pela fração, a app pede o nome (único na fração) no primeiro acesso, guarda a identidade no dispositivo, permite editar e anexa-o a cada reporte | Essencial | v0.3 | Draft |
| RF-11 | Gestão de identidades e QR codes | O administrador vê as identidades por fração, remove uma identidade (ex.: saída da fração) e revoga/regenera o QR code (ex.: divulgado a terceiros) | Essencial | v0.3 | Draft |
| RF-15 | Vários administradores | Um condomínio tem um ou mais administradores com as mesmas permissões; um administrador convida outro por código de uso único e pode removê-lo, exceto o último | Importante | v0.4 | Draft |

## Requisitos não funcionais

Cada requisito tem uma meta mensurável, a forma de a verificar e a justificação com o rastreio para o capítulo, a ADR ou as histórias que o concretizam. As metas são as definidas pela equipa em [5.4](./sprintA/sprintA.md#54-critérios-de-sucesso) e [8.7](./sprintA/sprintA.md#87-observabilidade); são verificadas em ambiente de teste com dados sintéticos, não com utilizadores reais.

| ID | Categoria | Requisito | O que significa | Métrica e meta | Verificação | Justificação e rastreio | Versão | Estado |
|---|---|---|---|---|---|---|---|---|
| RNF-01 | Usabilidade | Rapidez | Reportar demora menos de 1 minuto, mesmo com internet fraca | Reportar em < 1 minuto; hipótese de no máximo 5 interações | Teste end-to-end com rede lenta simulada; cronometragem pela equipa (indicativa) | O reporte rápido é a razão para sair do WhatsApp ([2.2](./sprintA/sprintA.md#22-conclusão-e-oportunidade-de-diferenciação)); US-02 | v0.6 | Draft |
| RNF-02 | Acessibilidade | Acessibilidade | Utilizável por pessoas com dificuldades de visão ou audição | Conformidade com WCAG 2.1 AA nos ecrãs do reporte e da lista; alternativas visuais às notificações | Ferramentas automáticas de acessibilidade, leitor de ecrã e teclado, avaliação heurística (Nielsen) | Inclusão de residentes pouco digitais e com limitações ([5.4](./sprintA/sprintA.md#54-critérios-de-sucesso)); US-08, ADR-002 | v0.6 | Draft |
| RNF-03 | Privacidade | Minimização de dados | Dados pessoais guardados só o tempo necessário e não partilhados sem necessidade; só se recolhe o nome, sem telefone nem e-mail | 0 campos de contacto recolhidos; só nome e fração | Testes automatizados de autorização e de esquema; só dados sintéticos | RGPD e a razão de ser do produto ([10.3](./sprintA/sprintA.md#103-minimização-e-finalidade-rgpd)); ADR-001, US-09 | v0.6 | Draft |
| RNF-04 | Segurança | Controlo de acesso | Só residentes com QR code válido da sua fração entram; token não adivinhável e revogável; administrador com permissões diferentes; limite de pedidos por IP na criação de identidades e de condomínios | Token aleatório com só o hash guardado; 100% das respostas a residentes sem fração nem nome do autor (salvo `mostrar_nome`) | Testes automatizados de autorização por papel e de IDOR; limite de pedidos testado | Modelo de ameaças TM-01, TM-06 e TM-10 ([10.6](./sprintA/sprintA.md#106-modelo-de-ameaças-inicial)); [10.2](./sprintA/sprintA.md#102-controlo-de-acessos), ADR-008 | v0.6 | Draft |
| RNF-05 | Observabilidade | Monitorização | Registo de erros para a equipa perceber rapidamente falhas | Logs JSON estruturados com `request_id`, `/health` e `/metrics` em API e Worker, contador `erros_total` | Inspeção dos logs e das métricas no dashboard operacional | A equipa tem de operar o sistema sem adivinhar ([8.7](./sprintA/sprintA.md#87-observabilidade)) | v0.6 | Draft |
| RNF-06 | Resiliência | Funcionamento sem internet | O que o utilizador cria (reportes, reuniões, áudio) fica em fila local e é enviado automaticamente quando a internet voltar, sem perda; os itens mantêm o autor | 0 itens perdidos nem duplicados após reenvio (`Idempotency-Key`) | Teste de resiliência sem rede e com reenvio | Prédios com cobertura fraca; ADR-006, US-18 | v0.6 | Draft |
| RNF-07 | Resiliência | Falha de serviços externos | Se um serviço externo falhar (calendário, IA), tenta alternativa quando existir, preserva os dados (ex.: áudio guardado, transcrição repetida) e informa que está em modo degradado | IA em baixo: áudio preservado e ata manual possível; calendário em baixo: iCal e depois dados locais; máximo de 5 tentativas com backoff | Testes de resiliência com falhas injetadas no simulador ([8.6](./sprintA/sprintA.md#86-integração-externa)) | Exigido pelo enunciado (6.5, 6.8); ADR-007, ADR-010, US-18 | v0.6 | Draft |
| RNF-08 | Privacidade | Identidade e retenção do nome | Nome visível só ao administrador e ao próprio (e aos outros se o autor o mostrar), nunca em logs nem avisos; apagado ao remover a identidade ("Residente removido"); retenção dos reportes: eliminados 24 meses depois de resolvidos; áudio apagado após a aprovação da ata | Reportes resolvidos eliminados aos 24 meses; áudio apagado após aprovação; 0 nomes em logs | Teste automatizado da limpeza diária e inspeção dos logs | [10.4](./sprintA/sprintA.md#104-retenção); US-09, US-10 | v0.6 | Draft |
| RNF-09 | Desempenho | Latência da submissão | `POST /reportes` responde depressa sob carga simulada | p95 < 1 s em ambiente de teste | Teste de carga em ambiente containerizado | SLI de [8.7](./sprintA/sprintA.md#87-observabilidade); RNF-01 | v0.6 | Draft |
| RNF-10 | Disponibilidade | Disponibilidade da submissão | O reporte está disponível quando o residente precisa | 99% em janela de 7 dias para `POST /reportes` | Métricas do dashboard operacional | SLI de [8.7](./sprintA/sprintA.md#87-observabilidade); RNF-06 cobre os períodos sem rede | v0.6 | Draft |
| RNF-11 | Desempenho | Processamento da ata | A ata fica pronta para revisão num tempo útil | >= 95% das atas em <= 15 min, para áudio até 60 min; custo <= US$ 0,50 por ata | Medição no conjunto de teste de [7.4](./sprintA/sprintA.md#74-abordagem-de-avaliação) | Justifica o processamento assíncrono ([8.5](./sprintA/sprintA.md#85-workflow-assíncrono)); US-10, ADR-010 | v0.6 | Draft |
| RNF-12 | Manutenibilidade | Qualidade automatizada | Cada alteração passa por verificações automáticas antes de entrar em `main` | CI verde: lint e análise estática, testes, SAST, SCA e verificação de segredos; PR aprovado por pelo menos 1 revisor | Pipeline em `.github/workflows/ci.yml` e Definition of Done | Equipa de 5 pessoas com um só stack ([11](./sprintA/sprintA.md#11-walking-skeleton)); ADR-003 | v0.6 | Draft |
| RNF-13 | Portabilidade | Execução reproduzível | Qualquer pessoa (incluindo os docentes) executa o backend sem contas externas | `docker compose up` arranca a API e a base de dados; app demonstrada em Android | Arranque documentado em `DomusCast/README.md` | Enunciado, secção 12; ADR-002, ADR-011 | v0.6 | Draft |
| RNF-14 | Custo | Custo operacional baixo | O produto é viável para um prédio de baixo orçamento | Infraestrutura de 6 a 20 € por mês; IA cerca de US$ 0,27 por ata de 1 h | Estimativa de [8.10](./sprintA/sprintA.md#810-estimativa-de-custos-operacionais), atualizada com medições | Proposta de valor de baixo custo ([2.3](./sprintA/sprintA.md#23-proposta-de-valor)) | v0.6 | Draft |
