# Refinamento do backlog - Sprint C

Aqui ficam as sessões de refinamento do Sprint C. Em cada uma, a equipa prepara as user stories até cumprirem a [Definition of Ready](../sprintA/sprintA.md#definition-of-ready-dor), com o desenho da interface, o contrato técnico e a validação planeada. O resultado fica nas colunas da DoR do [Sprint C Backlog](backlog.md); aqui ficam as decisões e o porquê. É o mesmo formato do [refinamento do Sprint B](../sprintB/refinamento.md).

## 2026-11-26

**Participantes:** Pedro Soares (Scrum Master), Luis Santos (Product Owner), Pedro Costa, Marco Garcia e Leonardo Costa.

**Objetivo:** criar o Sprint C Backlog. Há duas razões para o fazer antes do fim do Sprint B (2026-12-06). Cada pessoa sabe o que pega a seguir, e as dependências com histórias do Sprint B ainda em curso (US-05, US-22, US-24, US-25, US-18, US-31) ficam visíveis enquanto essas histórias se fecham.

**Seleção:** a equipa compromete-se a fechar todo o Sprint B Backlog até 2026-12-06, por isso o Sprint C fica com as histórias que o [plano de release](../backlog.md#2-plano-de-release-inicial-visão-multi-sprint) atribui ao Sprint C:

- **Should:** US-26, US-06, US-14, US-32, US-08, US-19 e US-30.
- **Could:** US-11, US-17, US-34, US-16, US-12, US-33 e US-21.
- **Itens técnicos T-01 a T-05:** cobrem o que os [objetivos do Sprint C](../sprintA/sprintA.md#61-objetivos-dos-sprints) pedem e que não é uma user story: avaliação formal da IA, resiliência, carga e dashboard. A apresentação final fica fora do Sprint Backlog, porque não é incremento de produto.

**Compromisso:** 22 SP (Should e itens técnicos; eram 23 até à revisão de 2026-11-27), com as Could (7 SP) como esforço adicional por prioridade, como no Sprint B. Se uma história do Sprint B não cumprir a DoD a 2026-12-06, entra no topo do Sprint C e é revista no refinamento seguinte.

**Distribuição end-to-end:** os itens que dependem uns dos outros ficam com a mesma pessoa, que continua o trabalho do Sprint B na mesma área:

| Pessoa | Itens | SP | Porquê |
|---|---|---|---|
| Pedro Costa | US-06, US-14, US-32, US-34 | 6 | Avisos e ações do administrador sobre reportes; continua a US-05 e a US-22, que a US-14 e a US-32 reutilizam |
| Luis Santos | US-19, US-30, US-33, US-12, US-21 | 5 | Administradores, papéis e identidade; continua a US-01, a US-20 e a US-23 |
| Marco Garcia | US-11, US-17, US-16, US-08 | 6 | Notificações, seguir, indicador e acessibilidade, quase tudo na app |
| Leonardo Costa | US-26, T-01, T-02 | 6 | Atas e avaliação da IA; continua a US-10 |
| Pedro Soares | T-03, T-04, T-05 | 6 | Operação: resiliência, carga e dashboard; continua o Worker e o simulador da US-28 |

**Wireframes:** os 13 wireframes abaixo, em `design/`, foram revistos e aprovados na sessão. Seguem o estilo dos do Sprint B. A US-08 e os itens técnicos não criam ecrãs.

**Acessibilidade:** como no Sprint B, cada história com interface inclui na validação planeada o TalkBack em PT-PT, com teste de gestos, ativação e anúncio do erro.

### US-06: Quadro de avisos

[Wireframe](design/us-06.html) ([PNG](design/us-06.png)) aprovado.

- **Campos:** título de 1 a 120 caracteres e texto de 1 a 2000, com contador. O 8.3 não fixava limites. 120 caracteres cabem numa linha da lista, e 2000 são o mesmo limite da descrição de um reporte (US-02).
- **Sem editar nem apagar:** um aviso publicado é um registo do que o administrador comunicou. Corrige-se publicando outro e arquivando o errado.
- **Histórico:** o quadro mostra os avisos ativos e o separador "Histórico" os arquivados, os dois do mais recente para o mais antigo. O critério "avisos antigos consultáveis" precisava de uma regra para um aviso deixar de ser ativo. Por isso há o novo `POST /avisos/{id}/arquivar`, só para o administrador e com confirmação. Arquivar duas vezes dá `409 aviso_ja_arquivado`. A US-14 usa o mesmo `arquivado_em`.
- **Sem internet:** a US-18 cobre reportes, reuniões e áudio, não avisos. Sem ligação, a app não diz que publicou e o texto fica no formulário para tentar de novo.
- **`publicado_desde`:** o parâmetro de `GET /avisos` fica já nesta história, para a sincronização da US-34.

### US-14: Aviso ligado a um reporte

[Wireframe](design/us-14.html) ([PNG](design/us-14.png)) aprovado.

- **Entrada:** "Criar aviso de risco" no detalhe do reporte. Só aparece ao administrador, com o reporte por resolver e sem aviso ativo.
- **Local obrigatório:** de 1 a 200 caracteres, como o local da reunião (US-13). O critério pede "assunto e local" e o local é o que torna o aviso útil a quem passa.
- **Um aviso ativo por reporte:** um segundo dá `409 aviso_ja_existe`. Um reporte resolvido dá `409 reporte_resolvido`, porque o aviso seria arquivado logo a seguir.
- **Arquivo automático:** acontece na mesma transação da mudança para Resolvido, dentro de `registar_mudanca_estado` (US-05). Assim, fechar um reporte como duplicado (US-22) também arquiva o aviso, sem código repetido.
- **Privacidade:** o aviso mostra o nº do reporte, mas nunca o autor, os co-reporters nem a fração. Os reportes já são visíveis a todos, e o autor continua oculto segundo a US-09.

### US-32: Ocultar e repor um reporte

[Wireframe](design/us-32.html) ([PNG](design/us-32.png)) aprovado.

- **Motivo obrigatório:** de 1 a 500 caracteres, como a nota da US-05. Ocultar esconde informação de toda a gente e o histórico tem de explicar porquê (TM-05).
- **Histórico:** a tabela `reporte_historico` só guardava mudanças de estado. Ganha a coluna `acao` (`estado`, `ocultado`, `reposto`), com `estado` por omissão para as linhas existentes. Numa linha de ocultar ou repor, o estado anterior e o novo são iguais. A alternativa era uma tabela de auditoria à parte, que partiria o histórico em dois sítios.
- **Quem ocultou:** além de `reporte.oculto_em`, que já constava do 8.3 mas não da base de dados, entra `reporte.oculto_por`, pela mesma razão de `removida_por` na US-23.
- **Quem deixa de ver:** todos os residentes, incluindo o autor. Se o autor continuasse a ver, os dados de terceiros continuavam expostos no telemóvel dele. A lista omite o reporte, e o detalhe e a foto dão 404, a mesma resposta de um reporte que não existe (TM-06).
- **Repor:** a mesma rota com `oculto: false` e motivo. Ocultar duas vezes dá `409 ja_oculto` e repor um visível dá `409 nao_oculto`.

### US-26: Ler as atas aprovadas

[Wireframe](design/us-26.html) ([PNG](design/us-26.png)) aprovado.

- **Onde:** no separador Reuniões, com "Próximas | Atas". É o sítio onde o residente já procura a assembleia (US-27), e não obriga a um separador novo.
- **Contrato:** `GET /reunioes?desde=` passa a devolver `ata_aprovada_em`, para a lista não precisar de um pedido por reunião. `GET /reunioes/{id}/ata` responde a um residente só com `{texto_aprovado, aprovada_em, origem}`. Sem ata aprovada, dá `404 ata_nao_publicada`, a mesma resposta de "não existe", para não revelar que há um rascunho por aprovar.
- **Origem:** "Escrita pelo administrador" ou "Preparada com IA e revista pelo administrador", a partir de `ata.origem` (US-25). Cumpre a regra de 7.5 de nunca apresentar conteúdo de IA como facto verificado.
- **Sem cópia offline:** a ata é lida raramente e o critério não pede leitura sem rede. Sem ligação, a app mostra um erro e "Tentar novamente".

### US-19: Convidar outro administrador

[Wireframe](design/us-19.html) ([PNG](design/us-19.png)) aprovado.

- **Código:** 8 caracteres de um alfabeto sem símbolos ambíguos (sem 0/O, 1/I/L), mostrados em dois grupos de 4, para ditar ou escrever à mão. Só o hash fica guardado (como o QR code, 10.5), por isso o código só se vê quando é gerado.
- **Validade e uso único:** 48 horas, tempo para o novo administrador o receber e usar. O uso é um `UPDATE` condicional (`usado_em` nulo e `expira_em` no futuro): dois pedidos em simultâneo com o mesmo código criam um só administrador.
- **Abuso:** código errado, expirado ou já usado dá o mesmo `404 convite_invalido` (TM-01). Com 20 tentativas falhadas por hora por IP e 48 h de validade, adivinhar um código de 8 caracteres não é viável. Conta só as tentativas falhadas, pela mesma razão do limite da US-15: vizinhos partilham o IP.
- **Máximo de 5 administradores:** é um limite de abuso. Um prédio de 8 a 60 frações não precisa de mais. O 6.º dá `409 limite_administradores`, ao gerar o convite e ao usá-lo.
- **Uma sessão por telemóvel:** a app guarda uma credencial. Entrar como administrador termina a sessão de residente no telemóvel, com aviso. A identidade de residente continua na base de dados e o administrador pode removê-la (US-23).
- **Quem fez cada ação:** o histórico já guarda `autor_id` (US-05) e a ata `aprovada_por` (US-24). Com vários administradores, `GET /reportes/{id}` passa a devolver o nome do administrador em cada entrada do histórico, mas só a administradores. Os residentes continuam a ver só "administração".
- **Lista de administradores:** `GET /condominios/{id}/administradores` fica nesta história, porque o ecrã que gera o convite precisa dela; a US-30 só acrescenta remover.

### US-30: Remover um administrador

[Wireframe](design/us-30.html) ([PNG](design/us-30.png)) aprovado.

- **Remover-se a si próprio:** é permitido, exceto ao último. Quem deixa a gestão não precisa de pedir a outro que o remova.
- **Último administrador:** `409 ultimo_administrador`. Dois administradores podem remover-se um ao outro ao mesmo tempo, e o condomínio ficaria sem nenhum. Para o evitar, o pedido bloqueia as linhas `administrador` do condomínio (`SELECT ... FOR UPDATE`) antes de contar os ativos. O teste cobre esse caso.
- **Registo:** nova coluna `administrador.removido_por`, pela mesma razão de `identidade.removida_por` (US-23).
- **Efeito imediato:** a credencial removida recebe 401 em qualquer pedido; a app apaga-a e mostra "O seu acesso de administrador foi removido", como na US-23.

### US-08: Acessibilidade no reporte

Sem wireframe: a história não cria ecrãs, corrige os da US-02 e da US-03.

- **Âmbito:** o percurso de reportar e acompanhar (formulário, lista e detalhe). As histórias novas já validam o TalkBack na sua própria DoR, por isso a US-08 não as revê todas.
- **Critério verificável:** WCAG 2.1 AA (RNF-02). Contraste de pelo menos 4,5:1, alvos de toque de pelo menos 48 dp, rótulos em todos os controlos e texto a 200% sem perda de informação. O estado nunca depende só da cor: tem texto e ícone, como já acontece na US-05.
- **Validação:** testes de widget com as `meetsGuideline` do Flutter, Accessibility Scanner no emulador e o percurso completo com TalkBack em PT-PT, gravado em vídeo como nas evidências do Sprint B.
- **Notificações:** a alternativa visual à notificação depende da US-11, que é Could. Se a US-11 não entrar, o estado continua visível na lista e a história não fica bloqueada.

### US-11: Notificação de mudança de estado

[Wireframe](design/us-11.html) ([PNG](design/us-11.png)) aprovado.

- **Mecanismo:** `workmanager` de 15 em 15 minutos, o mínimo do Android ([ADR-009](../sprintA/sprintA.md#adr-009-notificações-locais-por-sincronização-em-segundo-plano-sem-fornecedor-de-push)). Chama `GET /reportes?filtro=meus&atualizado_desde=`, que inclui os reportes de que o residente é co-reporter (US-22).
- **Só mudanças de estado:** o telemóvel guarda o último estado conhecido de cada reporte e só notifica quando o estado muda. A primeira sincronização só guarda o estado, para não disparar notificações de tudo o que já existia.
- **`atualizado_desde`:** o parâmetro estava no 8.4, mas não na API. Entra nesta história e filtra por `reporte.atualizado_em`, que a US-05 já atualiza.
- **Texto mínimo:** "Reporte #12: Em curso", sem a descrição (TM-08). A notificação abre o detalhe.
- **Permissão:** no Android 13 ou superior, a permissão de notificações é pedida depois do primeiro reporte enviado, quando o residente percebe para que serve. Se recusar, a app funciona na mesma.
- **Definições:** ecrã novo, aberto pela engrenagem nos Reportes, com os interruptores das notificações (US-11 e US-34), do indicador (US-16) e o nome (US-21). Quem fizer primeiro uma destas histórias cria o ecrã.
- **Identidade removida:** um 401 pára a tarefa em segundo plano.

### US-17: Seguir um reporte

[Wireframe](design/us-17.html) ([PNG](design/us-17.png)) aprovado.

- **Idempotente:** seguir um reporte já seguido e deixar de seguir um que não se segue dão 204. A app pode repetir o pedido sem tratar erros.
- **Autor e co-reporters:** seguem automaticamente (a relação `reporte_seguidor` já existe) e não podem deixar de seguir: dá `409 segue_automaticamente`. Quem não quer ser notificado desliga as notificações nas Definições.
- **Privacidade:** os outros residentes não sabem quem segue. O residente recebe só `a_seguir` (verdadeiro ou falso) e o administrador só `n_seguidores`.
- **Notificações:** a tarefa da US-11 passa a usar `filtro=a_seguir`, que inclui os reportes do próprio, aqueles de que é co-reporter e os seguidos, como descrito em 8.5.

### US-34: Notificação de aviso novo e de ata aprovada

[Wireframe](design/us-34.html) ([PNG](design/us-34.png)) aprovado.

- **Mecanismo:** a mesma tarefa da US-11, com `GET /avisos?publicado_desde=` (US-06) e `GET /reunioes?desde=` com `ata_aprovada_em` (US-26).
- **Texto:** "Novo aviso: <título>" e "Ata aprovada: assembleia de <data>". O título é público para o prédio e é o que permite decidir se vale a pena abrir. Com o telemóvel bloqueado, a notificação tem visibilidade privada e mostra só "Conteúdo oculto" (TM-08).
- **Desligar:** interruptor próprio, "Avisos e atas", separado das notificações de estado.

### US-16: Indicador de progresso do prédio

[Wireframe](design/us-16.html) ([PNG](design/us-16.png)) aprovado.

- **Contagens:** no mês civil, no fuso Europe/Lisbon, conta os reportes que passaram a Resolvido nesse mês e os reportes por resolver criados nesse mês. A regra de 5.5 diz que o indicador é por período e não acumulado, para não desencorajar com abertos antigos.
- **Exclusões:** os duplicados (US-22) não contam como resolvidos, porque inflacionariam o número. Os ocultos (US-32) também não contam.
- **Contrato:** `GET /progresso?periodo=mes` devolve só `{periodo, resolvidos, abertos}`. Aceita só `mes`, o único que a app usa; outro valor dá 422.
- **Desligar:** preferência local nas Definições. Com o indicador desligado, a app nem faz o pedido.

### US-33: Atribuir o papel de comissão

[Wireframe](design/us-33.html) ([PNG](design/us-33.png)) aprovado.

- **Onde:** na lista de residentes da fração, junto a "Remover residente" (US-23). O papel é de uma identidade, e é aí que o administrador as vê.
- **Como a app sabe o papel:** novo `GET /identidades/me`, que devolve `{id, nome, fracao, papel}`. A app só mostra "Relatório da comissão" quando o papel é `comissao`. A US-21 reutiliza a mesma rota.
- **Só leitura:** o papel `comissao` não dá nenhuma permissão de escrita. Os testes confirmam o 403 nas rotas do administrador.

### US-12: Relatório de reportes da comissão

[Wireframe](design/us-12.html) ([PNG](design/us-12.png)) aprovado.

- **Período:** `de` e `ate` em `AAAA-MM-DD`; por omissão os últimos 30 dias; no máximo 12 meses, para limitar o tamanho da resposta sem paginação. `de` depois de `ate`, ou mais de 12 meses, dá `422 periodo_invalido`.
- **Conteúdo:** reportes com alguma entrada no histórico dentro do período, com o estado atual e cada mudança (data, estado, ação e nota).
- **Sem nomes nem frações:** a comissão é composta por residentes e o relatório serve para avaliar o administrador, não quem reportou (10.2).
- **Ocultos:** aparecem, para a comissão ver que o administrador os ocultou e quando, mas com a descrição trocada por "Reporte oculto pelo administrador".
- **Acesso:** papel `comissao` ou administrador; um residente sem o papel recebe 403.

### US-21: Corrigir o meu nome

[Wireframe](design/us-21.html) ([PNG](design/us-21.png)) aprovado.

- **Regras:** as da US-15: nome obrigatório e único na fração, ignorando maiúsculas, acentos e espaços. Pôr o mesmo nome, ou só mudar maiúsculas, é aceite, porque a identidade é a mesma.
- **Contrato:** `PATCH /identidades/me` `{nome}` atualiza `nome` e `nome_normalizado` e devolve o mesmo formato de `GET /identidades/me`.
- **Reportes:** o nome é lido da identidade em cada pedido, por isso os reportes com `mostrar_nome` passam a mostrar o novo nome sem migração.

### T-01 e T-02: Avaliação da IA

- **Divisão:** a avaliação de 7.4 não cabe em 3 SP. Fica dividida em preparar o conjunto (T-01) e executar e relatar (T-02).
- **Conjunto (T-01):** 10 guiões em PT-PT, gravados pela equipa, de 10 a 15 minutos cada. Cobrem as condições de 7.4: fala clara, ruído, sobreposição, sotaques, nomes, montantes, decisões corrigidas ou revogadas e uma instrução maliciosa. A ata de referência é anotada antes de ver as saídas da IA, com cada decisão e o excerto da transcrição manual que a suporta. Não se usam gravações reais.
- **Formato da referência:** um ficheiro por gravação, com a transcrição manual, a lista de decisões (texto e excerto) e os factos críticos (votações, responsáveis, datas, montantes). Os áudios ficam fora do Git se passarem o limite de tamanho do GitHub, e o relatório indica onde estão.
- **Execução (T-02):** cada gravação passa pelo mesmo caminho da US-10, num ambiente de teste. Um script calcula o WER (`jiwer`) e verifica que cada excerto citado existe na transcrição. As medidas manuais (cobertura, informação sem suporte, factos críticos) são feitas por duas pessoas. O esforço do administrador compara a revisão do rascunho com a ata manual, alternando a ordem entre membros.
- **Relatório:** `docs/sprintC/avaliacao-ia.md`, com os resultados por gravação e por condição difícil, a comparação com as metas, o custo real por ata e as versões dos modelos e do prompt. As metas de 7.4 são critérios de aceitação para demonstração, não validação para uso real.

### T-03, T-04 e T-05: Operação

- **Resiliência (T-03):** os cenários de 8.6 correm com Docker Compose e o `/_chaos` do simulador. O que se automatiza entra na CI. Os restantes ficam com passos, resultado esperado e obtido, logs e screenshots em `docs/sprintC/resiliencia.md`. Revisto a 2026-11-27: o calendário em baixo até `alternativo`, e a recuperação, ficaram automatizados no Sprint B pelo T-06 (`tests_e2e/`), por isso o T-03 parte desses testes e fica com quatro cenários (IA, rede, Worker e base de dados em baixo), mais confirmar que a reunião `alternativo` está no feed iCal. Mantém 2 SP: o calendário era a parte mais simples, e a fila sem rede na app continua a ser a maior.
- **Carga (T-04):** k6 contra `POST /reportes` e `GET /reportes` com dados sintéticos, num ambiente igual ao da VM. Mede o p95 (< 1 s) e a disponibilidade (99%) de 8.7 e o ponto em que deixam de se cumprir, para decidir se a VM de 2 vCPU e 4 GB chega (8.10). Corre depois do T-05, para ler CPU, memória e latência do lado do servidor.
- **Dashboard (T-05):** os containers `prometheus` e `grafana` são provisionados por ficheiro, para `docker compose up` trazer o dashboard pronto. O Prometheus lê o `/metrics` da API e dos workers, que o T-07 (Sprint B) já entrega, pela rede interna do Compose; nem o Prometheus nem o Grafana ficam públicos (TM-08).
- **Painéis do Grafana:** disponibilidade e latência p95 de `POST /reportes`, pedidos por código, jobs por estado e por tipo, duração dos jobs, falhas de integração por provider (calendário e IA) e idade do job pendente mais antigo.

**Modelo de dados e API:** as colunas novas (`reporte.oculto_em`, `reporte.oculto_por`, `reporte_historico.acao`, `administrador.removido_por`) e as rotas novas (`POST /avisos/{id}/arquivar`, `GET /identidades/me`) foram acrescentadas ao [8.3](../sprintA/sprintA.md#83-modelo-de-dados) e ao [8.4](../sprintA/sprintA.md#84-api-esboço) do Technical Design. Os números das migrações escolhem-se na implementação, a seguir à última da `main`, porque há migrações do Sprint B ainda por integrar.

**Resultado:** DoR cumprida em todos os itens do [Sprint C Backlog](backlog.md), validada por todos os participantes. Falta criar as issues GitHub de cada item, ou atualizar as que já existem, com o responsável atribuído no GitHub Projects.

## 2026-11-27

### T-05: Dashboard operacional

- **Âmbito reduzido:** o entregável 12 do Sprint 2 pede métricas iniciais, por isso o `/metrics` da API e do `worker-calendario` passou para o Sprint B, no item técnico T-07 (#159), com os logs estruturados. O T-05 fica só com o Prometheus, o Grafana e o dashboard.
- **Estimativa:** de 3 para 2 SP. O compromisso do Sprint C passa de 23 para 22 SP e o Pedro Soares fica com 6 SP.
- **Dependência nova:** o T-05 depende do T-07, que fecha no Sprint B.

**Resultado:** DoR do T-05 revista e cumprida.
