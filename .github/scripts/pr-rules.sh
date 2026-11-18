#!/usr/bin/env bash
# Regras dos PRs para a main (nome do branch, título do PR e commits).
#
# Uso: pr-rules.sh branch <nome>
#      pr-rules.sh mensagem <primeira linha do commit ou título do PR>
#   Imprime "true" se cumprir a regra e "false" caso contrário.
#
# Branches: feature/, feat/, bugfix/, chore/ ou ci/ seguido de um nome.
# Mensagens: "[#12] - texto", "#12 - texto", "12 - texto", "[#12, #13] - texto"
#   (como o .githooks/commit-msg) ou "Área: texto" para infraestrutura sem issue
#   (GitHub, Docker, Deploy, CI, Docs, Mobile, API). Merges, reverts e fixups
#   automáticos do Git são aceites.
set -euo pipefail

regra="${1:?Uso: pr-rules.sh branch|mensagem <texto>}"
texto="${2-}"

case "$regra" in
  branch)
    if [[ "$texto" =~ ^(feature|feat|bugfix|chore|ci)/[^[:space:]]+$ ]]; then
      echo true
    else
      echo false
    fi
    ;;
  mensagem)
    case "$texto" in
      "Merge "*|"Revert "*|"fixup! "*|"squash! "*) echo true; exit 0 ;;
    esac
    id='#?[0-9]+'
    ids="$id(, ?$id)*"
    area='(GitHub|Docker|Deploy|CI|Docs|Mobile|API)'
    if printf '%s\n' "$texto" | grep -Eq "^((\[$ids\]|$ids) - |$area: )[^[:space:]]"; then
      echo true
    else
      echo false
    fi
    ;;
  *)
    echo "Regra desconhecida: $regra" >&2
    exit 2
    ;;
esac
