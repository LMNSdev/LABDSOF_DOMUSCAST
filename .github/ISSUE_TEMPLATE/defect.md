---
name: Defect
about: Algo já implementado não funciona como esperado (app, API, pipeline ou documentação)
title: "[Defect] "
labels: bug
---

<!--
Um defect é um comportamento incorreto numa funcionalidade já implementada.
Funcionalidades novas ou alterações de âmbito devem ser registadas como User Stories.
Não incluir segredos, credenciais nem dados pessoais na descrição ou nas evidências.
-->

## Resumo
<!-- Em uma ou duas frases: o que falha e quem é afetado (residente, administrador ou equipa)? -->

## Contexto
- **Componente:** <!-- App Flutter / API / Worker ou IA / Base de dados / CI/CD ou Docker / Landing page / Documentação -->
- **Ecrã, endpoint ou ficheiro:** <!-- Ex.: POST /identidades ou DomusCast/api/app/routers/identidades.py -->
- **Ambiente:** <!-- Ex.: Android no emulador, VM de produção, docker compose local ou CI -->
- **User Story / issue / PR relacionada:** <!-- Ex.: US-15, #79 ou PR #102 -->
- **Versão ou commit:** <!-- Ex.: v0.3.0 ou abc1234 -->

## Passos para reproduzir
1.
2.
3.

## Comportamento
- **Esperado:** <!-- Citar o critério de aceitação ou o desenho técnico, se existir -->
- **Obtido:** <!-- Incluir o código HTTP, a mensagem de erro ou o ecrã -->

## Evidência
<!-- Teste que reproduz o problema, log, screenshot ou gravação. Um teste que falha é a melhor evidência. Ocultar dados pessoais e credenciais. -->

## Gravidade
<!-- Escolher uma. A equipa pode revê-la na triagem. -->
- [ ] **Crítica:** funcionalidade principal indisponível, sem alternativa viável.
- [ ] **Alta:** comportamento incorreto com impacto significativo, incluindo perda ou exposição de dados.
- [ ] **Média:** impacto limitado ou existe uma alternativa razoável.
- [ ] **Baixa:** impacto apenas visual, sem afetar a utilização.

## Causa provável
<!-- Opcional. Preencher só se houver evidência; não é preciso sugerir a correção. -->

## Critérios de aceitação da correção
- [ ] O problema foi reproduzido e a causa foi identificada.
- [ ] Existe um teste de regressão que falha antes da correção e passa depois, ou está justificado porque não é automatizável.
- [ ] O comportamento corrigido corresponde ao esperado.
- [ ] A documentação afetada foi atualizada, se aplicável.

<!--
O issue fecha quando a correção entrar na main por PR revisto (template bugfix),
com a CI a passar e a Definition of Done desse template cumprida.
-->
