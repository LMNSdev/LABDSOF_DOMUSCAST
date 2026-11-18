#!/usr/bin/env bash
# Diz se o que corre no servidor mudou entre duas versões, para decidir o deploy.
#
# Uso: server-changed.sh <versão-anterior> <commit-novo>
#   Imprime "true" se houver alterações em DomusCast/api/ ou DomusCast/deploy/
#   (ou se não houver versão anterior) e "false" caso contrário.
#
# Merges só de documentação, da app ou de configuração do GitHub geram versão,
# imagem e APK, mas não reimplantam o servidor (que ficaria igual).
set -euo pipefail

anterior="${1:-}"
novo="${2:?Uso: server-changed.sh <versão-anterior> <commit-novo>}"

if [ -z "$anterior" ]; then
  echo true
elif git diff --quiet "$anterior" "$novo" -- DomusCast/api DomusCast/deploy; then
  echo false
else
  echo true
fi
