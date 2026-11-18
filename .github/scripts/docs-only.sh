#!/usr/bin/env bash
# Diz se, desde a versão anterior, só mudou documentação (pasta docs/).
#
# Uso: docs-only.sh <versão-anterior> <commit-novo>
#   Imprime "true" se todos os ficheiros alterados estiverem em docs/ (não se cria
#   versão nova, ex.: o registo da daily) e "false" caso contrário, ou se não
#   houver versão anterior.
set -euo pipefail

anterior="${1:-}"
novo="${2:?Uso: docs-only.sh <versão-anterior> <commit-novo>}"

if [ -z "$anterior" ]; then
  echo false
  exit 0
fi

alterados=$(git diff --name-only "$anterior" "$novo")
if [ -n "$alterados" ] && ! grep -qv '^docs/' <<< "$alterados"; then
  echo true
else
  echo false
fi
