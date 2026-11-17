# Refinamento do backlog - Sprint B

Sessões de refinamento do Sprint B: a equipa prepara as user stories até cumprirem a [Definition of Ready](../sprintA/sprintA.md#definition-of-ready-dor), com o desenho da interface, o contrato técnico e a validação planeada. O resultado de cada história fica nas colunas da DoR do [Sprint Backlog](backlog.md); aqui ficam as decisões tomadas e o porquê. As sessões acontecem fora da [daily](daily-log.md).

## 2026-11-16

**Participantes:** Pedro Soares (Scrum Master), Luis Santos (Product Owner), Pedro Costa, Marco Garcia, Leonardo Costa.

**Objetivo:** ter uma história pronta por pessoa, para os 5 poderem começar. Refinaram-se as Must pela ordem das dependências: US-01, US-15, US-02, US-03, US-09 e US-20.

### US-01: Criar condomínio + QR code

[Wireframe](design/us-01.html) aprovado antes da implementação, que ficou com o Luis Santos.

- **Limites:** 1 a 200 frações por condomínio e 5 criações por hora por IP. A arquitetura só exige que existam limites (TM-09); estes valores cobrem os prédios-alvo (8 a 60 frações) com folga.
- **QR code gerado a pedido:** o servidor só guarda o hash do token (10.5), por isso um QR code não pode ser mostrado outra vez; o administrador gera um sempre que precisa.
- **QR codes anteriores continuam válidos:** gerar um novo não revoga os outros, para não invalidar um QR code enviado e ainda por ler. A revogação é a US-20.

As decisões tomadas já durante a implementação (partilha por imagem e link, letras das frações, credencial no armazenamento seguro) estão nas [evidências da US-01](us-01.md#decisões-tomadas-na-implementação).

### US-15: Identificar residente pelo nome

[Wireframe](design/us-15.html) aprovado.

- **Token inválido ou revogado:** a API responde 404 nos dois casos, para não revelar que tokens existiram (TM-01). Para o residente, a solução é a mesma: pedir um novo QR code ao administrador.
- **Limite de tentativas:** 10 por hora por IP, acima dos 5 da US-01, porque os vizinhos partilham muitas vezes a rede Wi-Fi do prédio e podem enganar-se no nome.
- **Máximo por fração:** 10 identidades ativas (proposta de 10.5); a 11.ª recebe 409.

### US-02 e US-09: Reportar avaria e privacidade do autor

[Wireframe da US-02](design/us-02.html) e [wireframe da US-09](design/us-09.html) aprovados. A opção "mostrar o meu nome" fica no formulário da US-02; o wireframe da US-09 mostra o mesmo reporte visto pelo autor, por outro residente e pelo administrador.

- **Foto:** uma, JPEG ou PNG, até 5 MB; com foto, o texto alternativo é obrigatório (acessibilidade, RNF-02).
- **Reenvio:** `Idempotency-Key` no cabeçalho, única por autor; um reenvio devolve 200 com o reporte já criado, sem criar outro.
- **Permissões:** o administrador não cria reportes (403, [10.2](../sprintA/sprintA.md#102-controlo-de-acessos)).
- **Privacidade:** a API recusa campos desconhecidos com 422, o que prova que nenhum contacto (telefone, e-mail) é aceite.

### US-03: Consultar reportes

[Wireframe](design/us-03.html) aprovado.

- **Atualização automática:** a lista atualiza ao abrir, ao voltar à app, de 30 em 30 segundos com a lista aberta e ao puxar para baixo. Cumpre "o estado atualiza automaticamente" sem depender das notificações da US-11, que é de outro sprint.
- **Paginação:** nenhuma no MVP. Um prédio tem 8 a 60 frações e os reportes resolvidos são apagados aos 24 meses, por isso a lista é pequena.
- **Filtro "a seguir":** fica para a US-17.

### US-20: Revogar QR codes

[Wireframe](design/us-20.html) aprovado.

- **Casos limite:** 404 ao revogar um QR code já revogado ou de outro condomínio; "revogar todos" sem QR codes ativos devolve 0 revogados.
- **Confirmação:** a app pede sempre confirmação, porque revogar não se desfaz.

**Resultado:** DoR cumprida nas US-01, US-15, US-02, US-03, US-09 e US-20.

## 2026-11-17

**Participantes:** Pedro Soares (Scrum Master), Luis Santos (Product Owner), Pedro Costa, Marco Garcia, Leonardo Costa.

**Objetivo:** o Luis Santos concluiu a US-01 e precisa de uma história nova. Escolheu-se a US-23, a Must seguinte que continua o trabalho dele no ecrã da fração.

### US-23: Remover identidade

[Wireframe](design/us-23.html) aprovado.

- **Listar residentes:** novo `GET /fracoes/{id}/identidades` (só administrador), porque o esboço da API (8.4) só tinha o `DELETE` e o administrador precisa de ver quem está na fração para escolher quem remover.
- **Quem removeu:** nova coluna `identidade.removida_por`. O critério pede que a ação fique registada com o administrador; numa coluna fica durável e testável, o que os logs não garantem.
- **Respostas:** 204 ao remover; 404 se já foi removida ou é de outro condomínio; 403 residente.
- **Telemóvel removido:** recebe 401 em qualquer pedido; a app apaga a credencial e mostra "O seu acesso foi removido". A pessoa pode voltar a entrar com um QR code válido e o nome fica livre, porque foi apagado.

**Resultado:** DoR cumprida na US-23.
