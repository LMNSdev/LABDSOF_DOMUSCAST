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

echo
if [ "$falhas" -eq 0 ]; then echo "Todos os testes passaram."; else echo "$falhas teste(s) falharam."; exit 1; fi
