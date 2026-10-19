<!--
Branch: release/<versao-ou-sprint>  ->  main   (ex.: release/sprint-a, release/v0.1.0)
Titulo do PR: Release <versao/sprint> - <resumo>
-->

## Release
**Versão / Sprint:** <!-- ex.: v0.1.0 / Sprint A -->
**Data prevista:**
**Objetivo do sprint:**

## User Stories incluídas
<!-- Ver docs/backlog.md e docs/sprintX/backlog.md -->
| US | Resumo | Issue / PR | Estado |
|---|---|---|---|
| US-XX | | #  | Done |

## Notas de release
### Novas funcionalidades
-

### Correções
-

### Alterações com impacto (breaking / migrações / configuração)
-

### Limitações conhecidas / itens adiados
-

## Verificação pré-release
- [ ] Todos os PRs das User Stories incluídas estão integrados e cumprem a Definition of Done
- [ ] CI a passar na branch de release (lint, testes, verificação de dependências)
- [ ] `docker compose up` arranca `api` e `postgres` e `/health` responde
- [ ] Testes de aceitação/fumo executados no ambiente de avaliação
- [ ] Migrações de base de dados testadas
- [ ] Variáveis de ambiente / configuração documentadas
- [ ] Sem segredos/credenciais nem dados pessoais no repositório
- [ ] Documentação do sprint e de requisitos atualizada (`docs/`)
- [ ] Versão/changelog atualizados

## Deploy
- [ ] Build e push das imagens para o GitHub Container Registry com a tag do commit
- [ ] Deploy para o ambiente de avaliação
- [ ] Plano de rollback definido: <!-- como reverter -->

## Pós-merge
- [ ] Tag criada em `main` (ex.: `v0.1.0`)
- [ ] Release publicada no GitHub com as notas acima
- [ ] Branch de release apagada
- [ ] Demo / sprint review preparada para os docentes
- [ ] Issues fechadas e backlog do próximo sprint atualizado
