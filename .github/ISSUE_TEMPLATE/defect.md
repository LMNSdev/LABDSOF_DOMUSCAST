---
name: Defect
about: Algo não funciona como devia (API, app, pipeline ou documentação)
title: "[Defect] <resumo curto do problema>"
labels: bug
---

<!--
Um defect é um comportamento errado em algo já implementado.
Funcionalidades novas ou mudanças de âmbito são User Stories, não defects.
-->

## Resumo
<!-- Uma ou duas frases: o que falha e quem é afetado (residente / administrador / equipa). -->

## Onde
- **Componente:** <!-- API / App Flutter / Base de dados / Pipeline (CI/CD) / Documentação -->
- **Ficheiro(s):** <!-- ex.: `DomusCast/api/app/routers/identidades.py` -->
- **User Story / PR de origem:** <!-- ex.: US-15 (#79), PR #102 -->
- **Versão ou commit:** <!-- ex.: v0.3.0 ou abc1234 -->

## Passos para reproduzir
1.
2.
3.

## Resultado esperado
<!-- O que devia acontecer (citar o critério de aceitação ou o desenho técnico, se existir). -->

## Resultado obtido
<!-- O que acontece. Incluir o código HTTP, a mensagem de erro ou o ecrã. -->

## Evidência
<!-- Teste automático que falha, log, screenshot ou gravação. Um teste que reproduz é a melhor evidência. -->

## Severidade
<!-- Escolher uma e apagar as outras. -->
- [ ] **Bloqueante:** impede o uso de uma funcionalidade principal ou a entrega; sem alternativa.
- [ ] **Alta:** funcionalidade errada ou perda/fuga de dados, mas há alternativa.
- [ ] **Média:** erro em casos menos comuns ou mensagem errada ao utilizador.
- [ ] **Baixa:** cosmético ou sem impacto no utilizador.

## Causa provável e correção sugerida
<!-- Opcional, se já se souber. -->

## Definition of Done do defect
- [ ] Teste automático que reproduz o defect (falha antes da correção, passa depois)
- [ ] Correção integrada na `main` por PR com revisão
- [ ] CI a passar
- [ ] Documentação atualizada, se o comportamento descrito mudou
