# Use of AI

Como a equipa usou IA no Sprint A: agentes, skills e prompts, criação e revisão de conteúdo, e como contestámos os resultados. Este documento descreve o que aconteceu, incluindo o que correu mal.

## Resumo

- Usamos IA para **rever texto**, **pesquisar informação**, **rever código** e **gerar a interface gráfica da app** (Flutter), onde o resultado da IA é melhor do que o que conseguimos fazer sem apoio.
- Trabalhámos com um **assistente de IA em modo agente no VS Code** (Copilot SDK), que lê ficheiros do repositório, corre scripts, consulta páginas web e propõe edições.
- Criámos duas **skills** no repositório para auditar e rever a documentação do Sprint A: [sprint-a-grader](../.github/skills/sprint-a-grader/SKILL.md) e [sprint-a-proofreader](../.github/skills/sprint-a-proofreader/SKILL.md).
- A IA **nunca faz commits**. Cada alteração fica na working tree, é revista por nós com `git diff` e só depois um membro da equipa decide se a commita.
- Os números e as notas que a IA produz (por exemplo "35/52") são **estimativas de apoio**.

## Agentes, skills e prompts

### O agente
O assistente trabalha dentro do VS Code com acesso a ferramentas: ler e procurar ficheiros, correr comandos, abrir páginas web, editar ficheiros e consultar o histórico do git. Não usámos subagentes. As regras que lhe impusemos (e que estão escritas nas skills) são:

- só altera ficheiros quando o pedimos, e as skills limitam-se ao Sprint A;
- nunca faz `commit`, `push` ou qualquer alteração ao histórico do git;
- não inventa investigação, feedback dos docentes, métricas nem datas;
- cada defeito que aponta tem de vir com a linha exata e uma citação.

### Skills
| Skill | Para que serve | Como funciona |
|---|---|---|
| [sprint-a-grader](../.github/skills/sprint-a-grader/SKILL.md) | Verificar se a documentação do Sprint A cumpre a grelha M1 e as atividades do Sprint A | Pontua os 14 componentes da grelha de 0 a 4 com evidência, corre um [verificador mecânico](../.github/skills/sprint-a-grader/scripts/check_docs.py) (links e âncoras, placeholders, pontos entre backlogs, DoR e DoD), cruza com os 10 entregáveis do enunciado e lista a correção para chegar ao nível 4 |
| [sprint-a-proofreader](../.github/skills/sprint-a-proofreader/SKILL.md) | Rever a escrita como um professor: língua (PT-PT), clareza, coerência e terminologia | Corre um [script de pré-verificação](../.github/skills/sprint-a-proofreader/scripts/check_text.py) (brasileirismos, grafias antigas, palavras repetidas, frases longas, variantes de termos) e depois lê os documentos e dá feedback por níveis, só em leitura |

Cada skill tem um `SKILL.md` com o procedimento e as regras, e uma pasta `references/` com a grelha, a lista de verificação e o modelo do relatório.

### Prompts
Pedimos em linguagem natural e fomos corrigindo o comportamento do agente com novos pedidos. O exemplo seguinte é um pedido real, escolhido por definir uma regra do agente:

- "Garante que a skill não faz commit sozinho, o autor deve sempre rever e, se concordar, ser ele a commitar as alterações."

Os pedidos seguem alguns padrões:

- **Impor uma regra** ("Garante que...") para limitar o agente: não fazer commits, ficar no âmbito do Sprint A, não avaliar tecnicamente.
- **Pedir uma revisão crítica** ("Revê se...") para o agente rever o seu próprio trabalho e justificar o que mantém.
- **Pedir justificação** ("Porque fizeste...?") para perceber a razão de uma decisão antes de a aceitar.
- **Verificar o que já existe** ("Isto já não está feito algures?") antes de aceitar que algo seja criado de novo.
- **Rejeitar texto que empurra trabalho para a equipa** ("Não quero coisas destas...") e pedir a alternativa: fazer o trabalho com fonte, ou dizer onde está.

## Criação de conteúdo

- **Interface gráfica da app:** gerada com IA, porque aí o resultado é melhor do que o que conseguiríamos fazer sem apoio. O resto do código e dos documentos é escrito pela equipa.
- **Skills e scripts de verificação:** escritos pelo agente a partir dos nossos pedidos e da grelha M1, e depois ajustados por nós (âmbito, proibição de commits, tom).
- **Propostas de texto para o Sprint A:** na revisão final, o agente redigiu propostas para a metodologia, os papéis, a DoR e a DoD, as dependências e os riscos, a evidência das personas, a viabilidade, as relações do modelo de dados, a conversão de custos, as ADR-011 e ADR-012, os requisitos não funcionais, os epics e as prioridades e o Sprint B backlog. Foram propostas: tratámo-las como rascunhos e cortámos ou reescrevemos o que não podíamos confirmar (ver abaixo).
- **Pesquisa de informação:** a IA ajudou a localizar fontes (documentação da OpenAI, preços da Hetzner, faturação do GitHub, taxas do BCE). Os preços, os nomes de modelos e as datas só entraram nos documentos depois de verificados na página oficial, com a data de consulta.

## Revisão de conteúdo

- **Verificadores mecânicos:** o `check_docs.py` e o `check_text.py` encontram erros repetíveis (links partidos, placeholders, pontos diferentes entre backlogs, brasileirismos, grafias antigas). Servem de prova, não de opinião.
- **Leitura integral e citação:** a IA lê os documentos completos e só reporta um problema com a citação da linha. Os pontos que o script sugere são confirmados à mão antes de entrarem no relatório.
- **Verificação de factos externos:** preços, nomes de modelos, datas de descontinuação e limites foram confirmados nas páginas oficiais, com a data. A regra da skill é nunca dizer que um nome está errado "de memória", porque o conhecimento da IA pode estar desatualizado.
- **Revisão humana:** lemos o `git diff`, decidimos o que ficava e só então se faz o commit.

## Como contestámos os resultados da IA

Nenhum resultado da IA foi aceite sem passar por um membro da equipa. Contestámos os resultados de quatro formas:

- **Exigir evidência:** quando a IA apontava um defeito ou uma pontuação sem citar a linha exata, pedíamos a citação. Se não a conseguia dar, o ponto saía do relatório. Os avisos dos scripts foram tratados da mesma forma: confirmados à mão, e descartados quando eram falsos positivos.
- **Pedir justificação antes de aceitar:** perguntámos "Porque fizeste...?" sempre que uma alteração não era óbvia. Quando a razão não se aplicava ao nosso contexto, desfizemos a alteração com base no `git diff`.
- **Verificar contra fontes externas:** preços, nomes de modelos, datas de descontinuação e taxas de câmbio propostos pela IA foram confrontados com a página oficial. Os valores que não coincidiam foram corrigidos com a fonte e a data de consulta, em vez de ficarem os da IA.
- **Recusar conteúdo que não podíamos confirmar:** nas propostas de texto do Sprint A, cortámos ou reescrevemos frases que afirmavam factos que a equipa não tinha (resultados de inquéritos, feedback dos docentes, métricas, datas) e frases genéricas que apenas empurravam trabalho para a equipa ("Não quero coisas destas..."). A alternativa pedida foi fazer o trabalho com fonte ou indicar onde a informação já estava.

Também contestámos o próprio comportamento do agente, e não só o conteúdo:

- **Duplicação:** antes de aceitar uma secção ou ficheiro novo, perguntámos "Isto já não está feito algures?". Quando já existia, a IA passou a apontar para o local existente em vez de repetir o conteúdo.
- **Âmbito e autonomia:** limitámos as skills ao Sprint A, retirámos a avaliação técnica ao proofreader e proibimos commits ("Garante que a skill não faz commit sozinho..."). Estas correções ficaram escritas nas regras das skills para não dependerem de cada conversa.
- **Autoavaliação:** pedimos à IA que revisse o seu próprio trabalho ("Revê se...") e justificasse o que mantinha. As pontuações que produziu (por exemplo "35/52") serviram para orientar correções, não como nota final.

## Limites e riscos que reconhecemos

- A IA pode produzir texto plausível mas incorreto. Por isso as alegações sobre preços, versões e datas só entram com fonte oficial e data.
- A IA tende a preencher lacunas. As lacunas que dependem de factos da equipa (resultados do inquérito, feedback dos docentes, wireframes, capacidade do sprint) ficam por preencher em vez de serem inventadas.
- As pontuações da IA são estimativas e dependem da forma como lê a grelha. Não as tratamos como notas.
- Parte do que o agente propôs foi redigido por ele. A responsabilidade pelo conteúdo que fica nos documentos é da equipa, que o revê antes de cada commit.
