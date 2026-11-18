#!/usr/bin/env bash
# Testes dos scripts da pipeline. Correr na raiz do repositório:
#   bash .github/scripts/tests.sh
# Usa tags reais da main (precisa do histórico completo e das tags).
set -uo pipefail

falhas=0
check() { # check <descrição> <obtido> <esperado>
  if [ "$2" = "$3" ]; then
    echo "OK    $1 -> $2"
  else
    echo "FALHA $1 -> '$2' (esperado '$3')"
    falhas=$((falhas + 1))
  fi
}

nv=.github/scripts/next-version.sh
check "sem tags"                    "$(bash $nv "" "")"                  v0.1.0
check "feat/ sobe o MINOR"          "$(bash $nv v0.2.3 feat/us-02)"      v0.3.0
check "feature/ sobe o MINOR"       "$(bash $nv v0.2.3 feature/us-15-x)" v0.3.0
check "fix/ sobe o PATCH"           "$(bash $nv v0.2.3 fix/bug)"         v0.2.4
check "docs/ sobe o PATCH"          "$(bash $nv v0.2.3 docs/x)"          v0.2.4
check "push direto sobe o PATCH"    "$(bash $nv v0.2.3 "")"              v0.2.4
check "a seguir ao MAJOR manual"    "$(bash $nv v1.0.0 feat/x)"          v1.1.0

sc=.github/scripts/server-changed.sh
check "primeira versão faz deploy"           "$(bash $sc "" v0.2.0)"     true
check "feat/us-01 mexeu na API"              "$(bash $sc v0.1.0 v0.2.0)" true
check "chore/codeowners não mexeu no servidor" "$(bash $sc v0.2.1 v0.2.2)" false

do=.github/scripts/docs-only.sh
check "sem versão anterior gera versão"       "$(bash $do "" fcd55a5)"            false
check "merge só de docs/ não gera versão"     "$(bash $do fcd55a5^1 fcd55a5)"     true
check "CODEOWNERS (fora de docs/) gera versão" "$(bash $do 1f7c607^1 1f7c607)"    false

pr=.github/scripts/pr-rules.sh
check "branch feature/ aceite"           "$(bash $pr branch feature/us-09-privacidade)" true
check "branch feat/ aceite"              "$(bash $pr branch feat/deploy-azure)"         true
check "branch bugfix/ aceite"            "$(bash $pr branch bugfix/12-login)"           true
check "branch chore/ aceite"             "$(bash $pr branch chore/ci)"                  true
check "branch ci/ aceite"                "$(bash $pr branch ci/semgrep)"                true
check "branch fix/ aceite"               "$(bash $pr branch fix/login)"                 true
check "branch docs/ aceite (dailies)"    "$(bash $pr branch docs/daily-2026-11-18)"     true
check "branch release/ aceite"           "$(bash $pr branch release/sprint-b)"          true
check "branch sem prefixo recusado"      "$(bash $pr branch us-09-privacidade)"         false
check "branch hotfix/ recusado"          "$(bash $pr branch hotfix/x)"                  false
check "prefixo sem nome recusado"        "$(bash $pr branch feature/)"                  false
check "commit [#12] - aceite"            "$(bash $pr mensagem '[#12] - Adiciona formulário')"      true
check "commit com várias issues aceite"  "$(bash $pr mensagem '[#12, #13] - Formulário')"          true
check "commit #12 - aceite"              "$(bash $pr mensagem '#12 - Formulário')"                 true
check "commit de infraestrutura aceite"  "$(bash $pr mensagem 'GitHub: deploy só na main')"        true
check "merge do Git aceite"              "$(bash $pr mensagem "Merge branch 'main' into x")"       true
check "commit sem issue recusado"        "$(bash $pr mensagem 'Corrige o login')"                  false
check "área desconhecida recusada"       "$(bash $pr mensagem 'Coisas: várias')"                   false
check "issue sem descrição recusada"     "$(bash $pr mensagem '[#12] - ')"                         false
check "issue sem separador recusada"     "$(bash $pr mensagem '[#12] Formulário')"                 false

echo
if [ "$falhas" -eq 0 ]; then echo "Todos os testes passaram."; else echo "$falhas teste(s) falharam."; exit 1; fi
