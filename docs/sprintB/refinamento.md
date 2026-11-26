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
