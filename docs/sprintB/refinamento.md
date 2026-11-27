# Refinamento do backlog - Sprint B

Sessões de refinamento do Sprint B: a equipa prepara as user stories até cumprirem a [Definition of Ready](../sprintA/sprintA.md#definition-of-ready-dor), com o desenho da interface, o contrato técnico e a validação planeada. O resultado de cada história fica nas colunas da DoR do [Sprint Backlog](backlog.md); aqui ficam as decisões tomadas e o porquê. As sessões acontecem fora da [daily](daily-log.md).

## 2026-11-16

**Participantes:** Pedro Soares (Scrum Master), Luis Santos (Product Owner), Pedro Costa, Marco Garcia, Leonardo Costa.

**Objetivo:** ter uma história pronta por pessoa, para os 5 poderem começar. Refinaram-se as Must pela ordem das dependências: US-01, US-15, US-02, US-03, US-09, US-20 e US-23.

**Distribuição:** US-01 com o Luis Santos, US-15 com o Pedro Soares, US-02 com o Pedro Costa, US-09 com o Marco Garcia e US-23 com o Leonardo Costa. A US-03 e a US-20 ficam para quem acabar primeiro.

### US-01: Criar condomínio + QR code

[Wireframe](design/us-01.html) aprovado antes da implementação, que ficou com o Luis Santos.

- **Limites:** 1 a 200 frações por condomínio e 5 criações por hora por IP. A arquitetura só exige que existam limites (TM-09); estes valores cobrem os prédios-alvo (8 a 60 frações) com folga.
- **QR code gerado a pedido:** o servidor só guarda o hash do token (10.5), por isso um QR code não pode ser mostrado outra vez; o administrador gera um sempre que precisa.
- **QR codes anteriores continuam válidos:** gerar um novo não revoga os outros, para não invalidar um QR code enviado e ainda por ler. A revogação é a US-20.

As decisões tomadas já durante a implementação (partilha por imagem e link, letras das frações, credencial no armazenamento seguro) estão nas [evidências da US-01](us-01.md#decisões-tomadas-na-implementação).

### US-15: Identificar residente pelo nome

[Wireframe](design/us-15.html) aprovado.

- **Token inválido ou revogado:** a API responde 404 nos dois casos, para não revelar que tokens existiram (TM-01). Para o residente, a solução é a mesma: pedir um novo QR code ao administrador.
- **Limite de tentativas:** contado por QR code e não por IP, porque os vizinhos partilham o IP público do Wi-Fi do prédio (ou o CGNAT da operadora) e, no dia em que o administrador distribui os QR codes, um limite por IP bloquearia o resto do prédio. Cada QR code aceita 30 tentativas por hora, o que chega para os 10 residentes de uma fração com enganos no nome. Por IP só contam as tentativas com token inválido ou revogado (20 por hora): um vizinho com um QR code válido nunca as gasta, e quem tenta tokens ao acaso é travado. Corrigido após a revisão do PR; a primeira proposta era 10 tentativas por hora por IP.
- **Máximo por fração:** 10 identidades ativas (proposta de 10.5). A 11.ª recebe 409 com `codigo: fracao_cheia`, distinto do `nome_duplicado`, para a app mostrar a mensagem certa: mudar o nome não resolve uma fração completa. Os erros seguem o formato `{codigo, mensagem, request_id}` de 8.4.
- **Finalidade do nome:** o ecrã diz só "para o administrador saber quem reportou cada problema", que é a finalidade de 10.3. Não promete contacto, porque não se recolhe telefone nem e-mail (transparência, RGPD).

### US-02 e US-09: Reportar avaria e privacidade do autor

[Wireframe da US-02](design/us-02.html) e [wireframe da US-09](design/us-09.html) aprovados. A opção "mostrar o meu nome" fica no formulário da US-02; o wireframe da US-09 mostra o mesmo reporte visto pelo autor, por outro residente e pelo administrador.

- **Foto:** uma, JPEG ou PNG, até 5 MB; com foto, o texto alternativo é obrigatório (acessibilidade, RNF-02).
- **Reenvio:** `Idempotency-Key` no cabeçalho, única por autor; um reenvio devolve 200 com o reporte já criado, sem criar outro.
- **Permissões:** o administrador não cria reportes (403, [10.2](../sprintA/sprintA.md#102-controlo-de-acessos)).
- **Privacidade:** a API recusa campos desconhecidos com 422, o que prova que nenhum contacto (telefone, e-mail) é aceite. Como o pedido é multipart e o FastAPI ignora por omissão campos `Form` a mais, a implementação recebe o formulário num modelo Pydantic com `extra="forbid"` (`Annotated[Modelo, Form()]`). Corrigido após a revisão do PR.

### US-03: Consultar reportes

[Wireframe](design/us-03.html) aprovado.

- **Atualização automática:** a lista atualiza ao abrir, ao voltar à app, de 30 em 30 segundos com a lista aberta e ao puxar para baixo. Cumpre "o estado atualiza automaticamente" sem depender das notificações da US-11, que é de outro sprint.
- **Paginação:** nenhuma no MVP. Um prédio tem 8 a 60 frações e os reportes resolvidos são apagados aos 24 meses, por isso a lista é pequena.
- **Filtro "a seguir":** fica para a US-17.

### US-20: Revogar QR codes

[Wireframe](design/us-20.html) aprovado.

- **Casos limite:** 404 ao revogar um QR code já revogado ou de outro condomínio; "revogar todos" sem QR codes ativos devolve 0 revogados.
- **Confirmação:** a app pede sempre confirmação, porque revogar não se desfaz.

### US-23: Remover identidade

[Wireframe](design/us-23.html) aprovado.

- **Listar residentes:** novo `GET /fracoes/{id}/identidades` (só administrador), porque o esboço da API (8.4) só tinha o `DELETE` e o administrador precisa de ver quem está na fração para escolher quem remover.
- **Quem removeu:** nova coluna `identidade.removida_por`. O critério pede que a ação fique registada com o administrador; numa coluna fica durável e testável, o que os logs não garantem.
- **Respostas:** 204 ao remover; 404 se já foi removida ou é de outro condomínio; 403 residente.
- **Telemóvel removido:** recebe 401 em qualquer pedido; a app apaga a credencial e mostra "O seu acesso foi removido". A pessoa pode voltar a entrar com um QR code válido e o nome fica livre, porque foi apagado.

**Resultado:** DoR cumprida nas US-01, US-15, US-02, US-03, US-09, US-20 e US-23.

## 2026-11-19

**Participantes:** Pedro Costa, Pedro Soares e Luis Santos.

**Objetivo:** refinar as duas Must ainda por preparar e, dentro do mesmo conjunto de sete US da sessão anterior, as cinco Should com maior prioridade no backlog: US-05, US-22, US-13, US-10, US-24, US-25 e US-28. A US-13 desbloqueia as reuniões; US-10, US-24 e US-25 cobrem a ata assistida, a aprovação humana e o fallback manual; US-28 cobre a integração externa exigida para o Sprint B.

**Distribuição end-to-end:** US-05 e US-22 com Pedro Costa; US-13 e US-28 com Pedro Soares; US-24 e US-25 com Marco Garcia; US-10 com Leonardo Costa. O Luis Santos fica com a US-20 e a US-23. Cada US tem uma pessoa responsável pelo percurso completo, sem divisão por camada. (Corrigido a 2026-11-21: o primeiro registo desta linha não correspondia à distribuição acordada na sessão.)

**Estado:** a seleção, os participantes e a distribuição acima foram confirmados. Os sete wireframes foram revistos e aprovados por Pedro Soares. Os contratos e limites seguintes continuam a ser propostas preparadas para validação da equipa, não decisões aprovadas, exceto os da US-13, aprovados na sessão. Por isso, as linhas mantêm a DoR pendente no [Sprint Backlog](backlog.md), exceto a US-13 (Sim, 2026-11-19).

**Acessibilidade:** para cada US com interface, a validação planeada inclui TalkBack em PT-PT, com teste de gestos, ativação e anúncio de erro.

### US-05: Mudar estado + histórico

[Wireframe](design/us-05.html) ([PNG](design/us-05.png)) aprovado.

- **Transições:** proposta de permitir apenas Aberto -> Em curso -> Resolvido, sem regressões nem repetir o estado. Evita reabrir um reporte resolvido sem uma história específica para isso.
- **Nota auditável:** proposta de nota obrigatória entre 1 e 500 caracteres. O backlog pede uma nota, mas não define se é obrigatória nem o limite; confirmar ambos antes de fechar a DoR.
- **Persistência e acesso:** cada alteração acrescenta uma linha a `reporte_historico` com estado anterior/novo, nota, administrador e data; não se altera nem apaga histórico. Só administrador pode mudar o estado. O residente consulta a atualização pela US-03.
- **Falhas:** `409` para transição inválida ou reporte já resolvido, distinguido por `codigo`; `422` para campos inválidos. Erros mantêm `{codigo, mensagem, request_id}`. Sem fila offline: não mostrar sucesso se a API não confirmou.
- **Validação:** transições permitidas e recusadas, nota nos limites, histórico imutável, 403 para residente, 404 para outro condomínio e erro de base de dados. Na app, validar o anúncio do estado/erro com TalkBack.

### US-22: Marcar reporte como duplicado

[Wireframe](design/us-22.html) ([PNG](design/us-22.png)) aprovado.

- **Ligação:** `POST /reportes/{id}/duplicado` recebe `original_id`. Proposta de só aceitar reportes do mesmo condomínio, diferentes entre si, e de não aceitar um original que já seja duplicado. Evita relações entre condomínios, autorreferências e cadeias ambíguas.
- **Fecho e histórico:** o reporte repetido fica Resolvido, com `duplicado_de_id` e uma entrada no histórico com "Reporte duplicado do #<id>". A lista da US-03 apresenta a ligação.
- **Co-reporter:** o autor passa a `co_reporter` do original; se já existir uma relação, não se cria uma segunda. Não requer US-17, que trata de seguir reportes.
- **Respostas:** `200` ao marcar; `403` residente; `404` para reporte inexistente ou de outro condomínio; `409` para relação inválida ou duplicação já efetuada; `422` para pedido inválido. Distinguir conflitos por `codigo`.
- **Validação:** autor visível em "Os meus reportes", relação única, histórico, reporte/original iguais, original já duplicado, origem já duplicada, autorização, isolamento do condomínio e anúncio de falha com TalkBack.

### US-13: Agendar reunião

[Wireframe](design/us-13.html) ([PNG](design/us-13.png)) aprovado.

**DoR:** cumprida nesta sessão. A equipa aprovou os limites (data no futuro com fuso Europe/Lisbon, local de 1 a 200 caracteres) e a passagem da fila sem internet para a US-18.

- **Campos:** `data_hora` ISO 8601 com fuso Europe/Lisbon, apenas no futuro, e `local` obrigatório com 1 a 200 caracteres. A arquitetura não fixava fuso, horizonte temporal nem limite do local; estes valores foram confirmados na sessão.
- **Percurso:** administrador cria a reunião; residentes e administrador consultam `GET /reunioes?desde=`. `POST /reunioes` devolve `201`; a lista devolve `200`, incluindo lista vazia. A criação persiste a reunião antes de qualquer sincronização externa.
- **Dependências:** a publicação assíncrona pertence à US-28. A fila local sem internet pertence à US-18, que fica sequenciada depois e ainda não foi refinada; até lá, a app não deve afirmar que guardou uma reunião offline.
- **Falhas:** `403` residente ao criar, `422` data/local inválidos, `503` base de dados indisponível. O estado pendente da publicação não significa que a reunião se perdeu.
- **Validação:** criação e leitura nos dois papéis, data passada/fuso inválido, local vazio/acima do limite, lista vazia, publicação pendente, falha de rede e TalkBack.

### US-10: Transcrição de ata por IA

[Wireframe](design/us-10.html) ([PNG](design/us-10.png)) aprovado.

- **Privacidade:** antes do upload, informar que áudio e transcrição são enviados à OpenAI. Áudio, transcrição e rascunho ficam acessíveis só aos administradores; só a ata aprovada é visível aos residentes.
- **Processamento:** `POST /reunioes/{id}/ata/audio` aceita multipart, guarda o áudio e enfileira um job. Responde `202` com `a_transcrever`; `GET /reunioes/{id}/ata` mostra estado e resultado. O Worker faz até 5 tentativas com backoff de 1, 2, 4, 8 e 16 minutos; ao falhar, usa `falhou_transcricao`. Um reenvio depois de falha reutiliza o job, sem duplicar.
- **Dados preservados:** áudio permanece guardado mesmo após falha e só é apagado após aprovação; o rascunho nunca é publicado automaticamente e uma resposta tardia não substitui ata aprovada.
- **Pontos por decidir:** a arquitetura fixa partes de até 25 MB para a API de transcrição, mas não o limite total de upload nem os formatos aceites. `413` e `415` estão previstos no contrato, mas os valores/lista ainda não estão definidos. A DoR fica pendente até confirmação.
- **Validação:** estados assíncronos, formato/tamanho após decisão, falha após 5 tentativas, áudio preservado, reenvio idempotente, isolamento por papel, anúncio de estados/erros com TalkBack e aviso de privacidade.

### US-24: Rever e aprovar a ata

[Wireframe](design/us-24.html) ([PNG](design/us-24.png)) aprovado.

- **Edição e aprovação:** só o administrador edita o rascunho e consulta a transcrição. Aprovar publica o texto confirmado; não há publicação intermédia.
- **Integridade:** o Worker não atualiza uma ata em estado `aprovada`. `aprovada_por` guarda o administrador que aprovou; o áudio, a transcrição e o rascunho são apagados após a aprovação, ficando `texto_aprovado`.
- **Modelo de dados:** acrescentada a proposta `ata.aprovada_por` à tabela em [8.3](../sprintA/sprintA.md#83-modelo-de-dados), porque `aprovada_em` sozinho não identifica quem decidiu.
- **Pontos por decidir:** o limite de caracteres do texto editado não consta da arquitetura nem do backlog; definir antes de aprovar a DoR. `409` distingue ata já aprovada e ata sem rascunho.
- **Validação:** confirmar que nenhum rascunho é publicado, que o autor da aprovação fica registado, que uma resposta tardia não sobrescreve texto e que residentes recebem apenas ata aprovada. Validar o diálogo de confirmação e TalkBack.

### US-25: Ata manual (fallback não-IA)

[Wireframe](design/us-25.html) ([PNG](design/us-25.png)) aprovado.

- **Fallback:** o administrador pode escrever uma ata quando a IA está indisponível ou a transcrição falhou. Não depende da disponibilidade da OpenAI.
- **Aprovação comum:** reutiliza o fluxo de US-24; guardar um rascunho manual não o publica. Depois de aprovar, a app indica que a ata é manual.
- **Modelo de dados:** acrescentada a proposta `ata.origem` com `ia` ou `manual` em [8.3](../sprintA/sprintA.md#83-modelo-de-dados), para conservar a origem da ata depois da publicação.
- **Conflitos:** `409 ata_em_processamento` se ainda houver um processamento ativo e `409 ata_ja_aprovada` se a reunião já tiver uma ata publicada. O limite de texto é o mesmo ponto pendente da US-24.
- **Validação:** ata manual criada e publicada sem rascunho de IA, origem indicada ao residente, falha de rede sem perda do texto, IA indisponível e rejeição de alteração após aprovação. Validar TalkBack.

### US-28: Publicar reunião no calendário externo

[Wireframe](design/us-28.html) ([PNG](design/us-28.png)) aprovado.

- **Outbox e estado:** `POST /reunioes` cria o job `publicar_calendario:{reuniao_id}` na mesma transação da reunião; o Worker atualiza `estado_sync` para `sincronizada` ou `alternativo`. A app lê o estado em `GET /reunioes?desde=`.
- **Contrato externo:** enviar os campos descritos em 8.6; validar `id`, `start` e datas coerentes. Aplicar timeout de 10 segundos e até 5 tentativas com o backoff do workflow; respeitar `Retry-After` em 429. Após esgotar tentativas, a reunião mantém-se disponível pelo feed iCal e fica `alternativo`.
- **Dependências e falhas:** testar modos `indisponivel`, `lento`, `incompleto` e `invalido`; resposta incompleta/inválida conta como falha. US-29 (feed iCal) e US-18 (dados/fila local) têm de ser refinadas e sequenciadas antes de validar os respetivos fallbacks. A forma de tratar `400` do simulador e a interação exata de `Retry-After` com o limite de tentativas devem ser confirmadas antes da DoR.
- **Validação:** sucesso sem job duplicado, cada modo de falha, estado visível ao administrador, fallback iCal e ausência de perda da reunião. Validar rótulos e erros com TalkBack.

**Sincronização documental:** o Product Backlog mantém os critérios de aceitação existentes; esta sessão acrescenta detalhes técnicos, sem os substituir. Foram atualizados o Sprint Backlog e o modelo `ata` do Technical Design. US-18 e US-29 continuam dependências por refinar para fechar o percurso offline e o fallback iCal. Depois de a equipa aprovar os contratos, atualizar também as issues GitHub das sete US para manter os registos consistentes. As colunas DoR permanecem por confirmar até essa validação.

## 2026-11-24

**Participantes:** Pedro Soares, Luis Santos, Pedro Costa, Marco Garcia e Leonardo Costa.

**Objetivo:** fechar os dois pontos que a sessão de 2026-11-19 deixou por confirmar na US-28 e validar as decisões tomadas durante a implementação.

### US-28: Publicar reunião no calendário externo

- **`400` do simulador:** conta como falha normal, com nova tentativa e backoff.
- **`429` com `Retry-After`:** conta como tentativa; a seguinte fica agendada para o maior entre o backoff e o `Retry-After`, mantendo o limite de 5.
- **Tentativas:** 5 tentativas com esperas de 1, 2, 4 e 8 minutos; com 5 tentativas só há 4 esperas, por isso os 16 minutos de 8.5 não se usam.
- **Sem duplicar eventos:** o Worker escolhe o id do evento (`domuscast<reuniao_id>`); o `409` do simulador conta como já publicado. Acrescentado ao contrato de 8.6, com o modo `limite` do `/_chaos` para provocar o `429`.
- **Dados locais:** a app guarda a última lista de reuniões por condomínio e mostra-a quando a API não responde (ecrã 4 do wireframe). A fila de reuniões criadas sem internet continua a ser a US-18.
- **Fallback iCal:** a US-28 garante que a reunião fica guardada e marcada `alternativo`; verificar que aparece no feed é critério da US-29 (#92).
- **Diferenças ao wireframe:** ícones nos estados, título "Assembleia de condóminos" e ano nos cartões, botão "Agendar reunião" fixo no fundo (como na US-13).

**Resultado:** DoR da US-28 cumprida, validada por todos os participantes.

## 2026-11-26

**Participantes**: Marco Verbruggen, Luís Santos, Pedro Soares, Pedro Costa, Leonardo Costa

### US-29: Feed iCal do condomínio

[Wireframe](design/us-29.html) ([PNG](design/us-29.png)) proposto

- **Token derivado:** em vez de `condominio.calendario_token_hash` ([8.3](../sprintA/sprintA.md#83-modelo-de-dados)), guarda-se `condominio.calendario_token_versao` e o token é `HMAC-SHA256(SEGREDO_CALENDARIO, "{condominio_id}:{versao}")`, em base64 URL-safe (43 caracteres). Com só o hash, o link seria mostrado uma única vez e voltar a partilhá-lo obrigaria a regenerar, o que corta a subscrição a todo o condomínio, porque há um só token por condomínio. Continua sem token guardado em claro (10.5); regenerar incrementa a versão num só `UPDATE`. A troca muda o Technical Design, por isso foram atualizados o 8.3, o 8.4, o 8.8 e o TM-08 do 10.6 de [sprintA.md](../sprintA/sprintA.md).
- **`SEGREDO_CALENDARIO`:** variável de ambiente da API, com pelo menos 32 caracteres e sem valor por omissão no código. Na VM fica no `.env` de `/opt/domuscast`, criado pelo `deploy.sh` com `openssl rand -hex 32` se ainda não existir, e o `docker-compose.prod.yml` recusa arrancar sem ele; o `docker-compose.yml` de desenvolvimento tem um valor fixo, só para uso local. Se faltar ou for curto, as três rotas do calendário respondem 503 e o resto da API continua a funcionar. Mudar o segredo invalida os links de todos os condomínios, por isso nunca se muda depois de criado.
- **Ver o link:** novo `GET /condominios/{id}/calendario`, que devolve `{url}` ao administrador e aos residentes do condomínio; 401 sem credencial, 404 de outro condomínio, sem revelar que existe ([8.4](../sprintA/sprintA.md#84-api-esboço)). O residente vê-o no separador Reuniões, sem depender da US-27. Só o administrador regenera (`POST .../calendario/regenerar`, 200 com o novo `{url}`, 403 residente, 404 de outro condomínio), depois de confirmar. Para a app do residente saber o condomínio, `POST /identidades` passa a devolver também `condominio_id` (US-15); numa sessão criada antes disso, a app pede ao residente que peça o link ao administrador.
- **Sem `webcal_url`:** a app não abre `webcal://` e o wireframe não o usa, por isso o contrato devolve só o `url` em `https`.
- **Feed:** `GET /condominios/{id}/calendario.ics?token=`, sem credencial Bearer, porque as apps de calendário não a enviam. O parâmetro `token` é opcional (`token: str | None = None`), para um token em falta dar 404 e não 422, e compara-se com `hmac.compare_digest`. Token em falta, inválido, antigo ou de outro condomínio, e condomínio inexistente: 404 nos cinco casos, para não revelar que o condomínio existe (TM-01).
- **429 só para tokens inválidos:** o Google Calendar e o Outlook vão buscar os feeds a partir de poucos IPs partilhados por todos os condomínios. A API verifica o token primeiro e um token válido nunca recebe 429; só os pedidos com token inválido contam para o limite de 20 por hora por IP. Assim, as subscrições antigas que continuam a pedir um link regenerado não bloqueiam o feed de outros condomínios pedido do mesmo IP.
- **Token fora dos logs:** o uvicorn regista no access log o caminho completo de cada pedido, com a query string. Um filtro no logger `uvicorn.access` troca o valor de `token=` por `***`, mantendo o resto da linha para diagnóstico (TM-08). O Caddy não tem access log ativo.
- **Conteúdo:** as reuniões dos últimos 12 meses e as futuras, qualquer que seja o `estado_sync`, porque o feed é o fallback da US-28. Cada reunião é um `VEVENT` com `UID` estável `reuniao-{id}@domuscast`, para não duplicar ao atualizar, e 2 horas de duração, porque a reunião não tem hora de fim. `SUMMARY` é sempre "Assembleia de condóminos", como na US-28, e `LOCATION` é o local; o evento não leva nomes, frações, estado da publicação nem texto da ata (TM-08). Gerado com a biblioteca `icalendar` (RFC 5545).
- **Datas em UTC:** `reuniao.data_hora` está em UTC e `DTSTART` e `DTEND` são escritos em UTC, com o sufixo `Z`; sem fuso, a app de calendário trataria a hora como hora local de quem subscreve. As reuniões ainda não se editam (US-13), por isso `LAST-MODIFIED` e `DTSTAMP` são `criado_em` e `SEQUENCE` é 0. Quando o PR #129 (US-28) entrar com `reuniao.atualizado_em`, `LAST-MODIFIED` passa a usá-la; `SEQUENCE` só deve subir quando houver edição de data, hora ou local, não quando muda o `estado_sync`.
- **Migração:** `0010`, com `down_revision = "0009"`.
- **Subscrever no telemóvel:** a app do Google Calendar para Android não subscreve por URL, por isso a app não abre o `webcal://`: mostra o link com "Copiar" e "Partilhar" e instruções para Google Calendar, Apple Calendar e Outlook. O ecrã avisa que uma reunião nova pode demorar até um dia a aparecer, porque o Google Calendar pode demorar até um dia a atualizar um calendário subscrito.
- **Validação:** feed válido (parse do `.ics`), um evento por reunião com `UID` estável, horas em UTC, só data, hora e local, reuniões `pendente` e `alternativo` incluídas, isolamento entre condomínios, 404 igual para token em falta, inválido, antigo ou de outro condomínio, 429 só para tokens inválidos, token válido sem 429, regenerar invalida o anterior, residente não regenera (403), 503 sem `SEGREDO_CALENDARIO` e token ausente do access log. Sucesso: subscrito no Google Calendar ou Outlook com o URL público da VM. App: TalkBack em PT-PT (gestos, ativação e anúncio dos erros).

### US-18: Fila local sem Internet

[Wireframe](design/us-18.html) ([PNG](design/us-18.png)) proposto. Os pontos seguintes são propostas para validação da equipa.

- **Ponto de partida:** a fila da US-02 (`queue.db`, tabela `pending_reportes`) só guarda reportes sem foto, não guarda o autor e só é enviada quando o residente abre a lista de reportes. Quando o envio recebe um 4xx que não seja 401, o item é apagado sem aviso, o que contraria o "sem perda" do critério. A US-18 alarga-a a reuniões e áudio, com uma fila por tipo.
- **Uma fila por tipo:** três tabelas no SQLite da app (`queue.db`): `pending_reportes` (a da US-02, alargada), `pending_reunioes` e `pending_audios`, cada uma com os campos do seu pedido. As três têm em comum `autor` (id da identidade ou do administrador e o papel), `idempotency_key` (nos reportes e nas reuniões), `ficheiro` (caminho da foto ou do áudio, copiado para a pasta privada da app), `estado` (`pendente` ou `recusado`), `motivo` e `criado_em`. Cada tabela tem colunas próprias em vez de um JSON genérico, como a fila da US-02 já faz. A migração da base local (versão 3) acrescenta as colunas novas a `pending_reportes`, preenchendo o autor com o da sessão atual, e cria as outras duas tabelas.
- **Autor:** cada item guarda quem o criou e só é enviado com a credencial dessa mesma identidade ou administrador. Se o telemóvel entrar com outra identidade (por exemplo, depois de removido e identificado de novo com outro nome), os itens antigos não são enviados com a nova credencial, porque ficariam com o autor errado. A credencial continua só no armazenamento seguro; a fila não a copia.
- **Envio:** um único serviço na app envia a fila, em vez do ecrã da lista de reportes. Corre ao arrancar a app, ao voltar ao primeiro plano, logo depois de guardar um item e, com a app aberta e itens pendentes, de 30 em 30 segundos, como a lista de reportes (US-03) e de reuniões (US-28). Um só envio de cada vez (trinco), para dois gatilhos seguidos não mandarem o mesmo item em paralelo. Sem envio com a app fechada: a sincronização em segundo plano é da US-11.
- **Ordem dentro de cada tipo:** cada fila é enviada por `criado_em`, do mais antigo para o mais recente; entre tipos não há ordem garantida. É seguro porque nenhum item depende de outro tipo: o áudio só existe para reuniões que já estão no servidor (ver Áudio). Uma falha transitória (sem ligação, timeout, erro de TLS, 5xx, 429) para o envio dessa fila e o item volta a ser tentado na vez seguinte, sem passar à frente dos outros do mesmo tipo.
- **Recusa definitiva sem perda:** um 4xx que não seja 401, 408 ou 429 (por exemplo 422, 403, 409 ou 413) marca o item como `recusado`, com o motivo da API, e o envio continua com o seguinte. O item não é apagado: aparece em "Por enviar" com o motivo, e o utilizador pode ver o texto ou remover o item. Uma reunião recusada (por exemplo, a data passou enquanto estava sem rede, 422) abre o formulário da US-13 com os dados preenchidos, para a reagendar.
- **Identidade removida (US-23):** um 401 para o envio e marca os itens desse autor como `recusados` com "O seu acesso foi removido". Ficam no telemóvel e o ecrã "O seu acesso foi removido" indica quantos itens por enviar ficaram guardados. Não são enviados se a pessoa voltar a entrar, porque seria outra identidade.
- **Reportes:** a foto (até 5 MB, já validada pela US-02) e o texto alternativo também entram na fila. Mantém-se a `Idempotency-Key` gerada quando o formulário é submetido pela primeira vez.
- **Reuniões:** `POST /reunioes` passa a receber o cabeçalho `Idempotency-Key` (1 a 64 caracteres, obrigatório, como em `POST /reportes`), guardado na nova coluna `reuniao.idempotency_key`, única por condomínio. Um reenvio com a mesma chave devolve 200 com a reunião já criada, sem criar outra nem outro job `publicar_calendario`. Muda o 8.3 e o 8.4 de [sprintA.md](../sprintA/sprintA.md), a atualizar depois da aprovação. Migração com o número seguinte ao da US-29 (hoje `0011`). A data continua a ser validada pela API no momento do envio. Sem ligação, o ecrã da US-13 deixa de mostrar o erro e passa a guardar a reunião na fila.
- **Áudio:** só para reuniões que já estão no servidor; o ecrã da ata não existe para uma reunião ainda na fila, por isso não há dependências entre itens. O ficheiro (até 200 MB, MP3, M4A ou WAV, como na US-10) é copiado para a pasta da app. O reenvio é idempotente sem chave nova: a US-10 compara o SHA-256 do áudio e devolve a mesma ata. `409 audio_diferente` ou `409 ata_ja_aprovada` marcam o item como `recusado`. Depende do PR #130 (US-10).
- **Ver o que falta enviar:** uma faixa "Por enviar (n)" no topo da lista de reportes (residente) e da lista de reuniões (administrador) abre o ecrã "Por enviar", com o estado de cada item. Ao guardar sem ligação, a app mostra "Sem ligação. O reporte fica guardado e é enviado quando a ligação voltar." (texto já usado na US-02), com a variante para a reunião e para o áudio. O item enviado sai da fila e os ficheiros copiados são apagados.
- **Lista de reportes sem ligação:** a lista de reportes passa a ficar guardada no telemóvel, como a US-28 fez para as reuniões (`reunioes_cache.dart`), e cumpre a nota do wireframe da US-03 ("a cache da última lista é da US-18"). Não é um critério do Product Backlog; a proposta é incluí-la nesta US, sem mudar a estimativa. A fila envia o que se cria; a cache mostra o que já veio do servidor.
  - **O que se guarda:** a última lista recebida de `GET /reportes`, em JSON, numa tabela `ultima_lista` de `reportes.db`, com a data em que foi recebida. Só texto (descrição, estado, datas, autor quando visível); as fotos não, para não ocupar espaço, e o cartão mostra "Foto disponível com ligação".
  - **Chave:** a sessão (id da identidade ou do administrador) e os filtros (`filtro` e `estado`), porque os filtros são aplicados pela API. Guardar só por condomínio, como na US-28, não chega: o administrador vê o nome e a fração de cada autor e o residente não (US-09), por isso a lista de uma sessão nunca pode aparecer a outra no mesmo telemóvel.
  - **Quando se mostra:** nas mesmas falhas da US-28: sem ligação, 5xx, timeout de 15 s, erro de TLS ou resposta que não é JSON. Um 4xx não usa a lista guardada. Aparece com o aviso "Sem ligação. A mostrar a lista guardada de DD/MM às HH:MM.", com a data, porque os estados dos reportes mudam. A atualização de 30 em 30 segundos da US-03 continua e o aviso desaparece quando a lista volta. Um filtro que nunca foi carregado com ligação mostra "Sem lista guardada para este filtro."
  - **Detalhe:** abrir um reporte sem ligação mostra os dados que estão na lista guardada e "O histórico precisa de ligação"; o histórico (US-05) não é guardado.
  - **Apagar:** quando a identidade é removida (401, US-23), a lista guardada dessa sessão é apagada, porque a pessoa deixou de ter acesso aos reportes do condomínio. Os itens da fila ficam, como pede o critério.
  - **Tamanho:** cada combinação de filtros guarda só a última lista, que substitui a anterior; sem paginação, a lista é pequena (US-03).
- **Fora:** editar um item na fila antes de ser enviado; envio com a app fechada (US-11).
- **Validação:** testes da app com as filas em memória (ordem dentro de cada tipo, paragem na falha transitória, item `recusado` sem perda, 401 recusa só os itens desse autor, itens de outra identidade não enviados, um só envio de cada vez, migração de `pending_reportes`) e da lista guardada (mostrada sem ligação, 5xx, timeout, TLS e resposta que não é JSON, não usada com 4xx, lista de outra sessão nunca aparece, filtro sem lista guardada, aviso com a data e que desaparece quando a ligação volta, apagada com 401). pytest: `Idempotency-Key` em `POST /reunioes` (reenvio devolve a mesma reunião, um só job, 422 sem cabeçalho, chave igual noutro condomínio não colide). Teste de resiliência ([5.4](../sprintA/sprintA.md#54-critérios-de-sucesso)) no emulador em modo de avião: 3 reportes (um com foto), 1 reunião e 1 áudio; ao repor a ligação, contar na base de dados 0 perdidos e 0 duplicados. Reenvio depois de a API ter gravado mas a resposta não ter chegado (API parada a meio): sem duplicado. App: TalkBack em PT-PT (faixa "Por enviar", ativação, anúncio do item recusado e do aviso da lista guardada).

### US-31: Modo degradado da app

[Wireframe](design/us-31.html) ([PNG](design/us-31.png)) proposto. Os pontos seguintes são propostas para validação da equipa.

- **Ponto de partida:** parte do modo degradado já existe. A US-28 mostra o estado `alternativo` em cada reunião, guarda a última lista no telemóvel e regista cada falha com `componente: "calendario"`; a US-10 mostra `falhou_transcricao` e "Tentar transcrição novamente"; a US-25 dá a ata manual. A US-31 fecha o que falta entre elas, sem repetir esse trabalho.
- **Só o administrador:** a IA e a publicação no calendário só dizem respeito ao administrador. O residente recebe a reunião pelo feed iCal (US-29) e a ata só depois de aprovada, por isso não vê avisos de modo degradado; o "sem ligação" do residente já está nas US-03 e US-28.
- **Calendário em baixo:** além do estado em cada reunião, o separador Reuniões do administrador mostra no topo "Calendário externo indisponível. As reuniões continuam no feed iCal e a publicação volta a ser tentada automaticamente." enquanto houver reuniões futuras `alternativo`. Texto em linguagem simples; a expressão "modo degradado" não aparece na app.
- **Tentar mais tarde:** hoje, à 5.ª falha, o job fica `falhou` e a reunião `alternativo` para sempre: se o serviço voltar 20 minutos depois, a reunião nunca chega ao calendário externo. Isto contradiz o Workflow 4 e o 8.6 ("regista o erro e tenta mais tarde") e deixaria o aviso do topo a prometer uma nova tentativa que não existe. Proposta:
  - **Quem e quando:** o Worker do calendário (US-28), que já está sempre a correr, procura de hora a hora as reuniões `alternativo` com data no futuro.
  - **O quê:** repõe como `pendente` o job que já existe (`publicar_calendario:{id}`), para uma única tentativa, sem novo ciclo de 5. Reutilizar o job mantém a chave de idempotência, sem jobs duplicados; o evento também não duplica, porque o id é `domuscast<id>` e o `409` do simulador conta como já publicado (US-28).
  - **Resultado:** se resultar, a reunião passa a `sincronizada` e, na lista seguinte (de 30 em 30 segundos), o cartão fica verde e o aviso do topo desaparece, sem ação do administrador. Se falhar, continua `alternativo` e volta a ser tentada na hora seguinte. Cada tentativa fica no log como na US-28.
  - **Porquê estes valores:** só reuniões futuras, porque publicar uma assembleia que já passou não serve para nada e assim a lista não cresce; uma só tentativa, porque o serviço já falhou 5 vezes e, se tiver voltado, uma basta; de hora a hora, como compromisso entre não insistir num serviço em baixo e não deixar uma reunião próxima muitas horas sem calendário. Automático e não um botão "Tentar publicar de novo", porque o botão precisaria de um endpoint novo e obrigava o administrador a lembrar-se.
  - **Em aberto para a equipa:** o intervalo (por exemplo, 30 minutos em vez de 1 hora), o número de tentativas por ciclo e se há um limite (por exemplo, parar 24 horas antes da reunião). A mudança é no Worker da US-28 (Pedro Soares), a fazer nesta US.
- **IA em baixo, antes das 5 tentativas:** a US-10 só mostra a falha no fim, que com as esperas de 1, 2, 4 e 8 minutos chega ao fim de cerca de 15 minutos. Proposta: depois da primeira falha, o ecrã da ata mostra "O serviço de IA não respondeu. Nova tentativa às HH:MM (tentativa 2 de 5). Pode escrever a ata manualmente." Para isso, `GET /reunioes/{id}/ata` passa a devolver `tentativas` e `proxima_tentativa_em` também enquanto a ata está `a_transcrever` (hoje só os devolve depois de falhar). É um campo no endpoint que já existe, não um endpoint novo.
- **Ata manual com a IA a tentar:** o critério diz que, com a IA em baixo, a ata manual está disponível, mas a US-25 responde `409 ata_em_processamento` enquanto houver um job ativo. Proposta: depois de pelo menos uma falha, `PUT /reunioes/{id}/ata` com uma ata manual é aceite, passa a ata a `origem=manual` e fecha o job da transcrição como `falhou`, com `erro` "substituida_por_ata_manual" (sem novo estado de job); o Worker, antes de gravar, confirma com a linha bloqueada que a ata continua `origem=ia` e, se não, descarta o resultado. Durante a primeira tentativa, o `409` mantém-se, para não se perder uma transcrição que está a correr bem. Muda a US-25 e o Worker da US-10.
- **Logs:** os dois Workers usam o mesmo formato JSON, com `timestamp`, `componente`, `evento` e o id do objeto. O Worker da US-28 já usa `componente: "calendario"`; o da US-10 usa `"worker"` e passa a `"ia"`. A US-28 já distingue cada falha (`tentativa_falhou`) da entrada em modo degradado (`publicacao_falhou`); a US-10 regista `transcricao_falhou` nos dois casos e passa a usar `tentativa_falhou` nas falhas intermédias. A recuperação de uma reunião `alternativo` fica como `publicada`, com o estado anterior. Sem áudio, transcrição nem nomes no log (8.6).
- **Critério "tenta outra alternativa antes de degradar":** no calendário, o feed iCal não é tentado, está sempre disponível; na IA não há segundo fornecedor (ADR-010). Proposta de redação no Product Backlog: "Antes de degradar, o sistema usa a alternativa que existe: no calendário, a reunião continua no feed iCal (US-29) e, sem acesso à API, nos dados locais; na IA, a ata manual (US-25)." A alterar no [Product Backlog](../backlog.md) só depois da aprovação.
- **Injetar a falha da IA:** o simulador do calendário já tem `/_chaos`, mas a OpenAI não tem forma de falhar a pedido. Proposta: o endereço da OpenAI passa a vir da variável `OPENAI_BASE_URL` (por omissão `https://api.openai.com/v1`); para a demonstração aponta para o simulador, que no modo `indisponivel` responde 503 também em `/ia/*`. O Worker da US-10 ganha o `WORKER_BACKOFF_UNIDADE_S` da US-28, para as esperas serem em segundos na demonstração.
- **Dependências:** US-28 (concluída), US-10 (PR #130) e US-25 (à espera da US-10). A DoR pode fechar antes, mas a US-31 só fica concluída depois dessas entrarem.
- **Estimativa:** com a nova tentativa de hora a hora, a ata manual durante as tentativas e o simulador da IA, os 2 SP parecem curtos. Proposta: 3 SP.
- **Validação:** pytest: reunião `alternativo` futura volta a ser tentada uma vez por hora e passa a `sincronizada`, reunião passada não é tentada; `tentativas` e `proxima_tentativa_em` em `a_transcrever`; ata manual aceite depois de uma falha e `409` durante a primeira tentativa; o Worker não grava sobre uma ata manual; formato dos logs com `timestamp` e `componente` nos dois Workers. Docker: simulador `indisponivel` para o calendário e para a IA, com screenshots dos avisos e da recuperação ao voltar a `ok`. App: aviso no topo das reuniões, aviso de nova tentativa e "Escrever ata manualmente"; TalkBack em PT-PT (avisos anunciados ao aparecer, ativação do botão).

