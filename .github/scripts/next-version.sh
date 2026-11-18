#!/usr/bin/env bash
# Calcula a próxima versão (SemVer) a partir da última tag e do branch do PR.
#
# Uso: next-version.sh <ultima-tag> <branch>
#   <ultima-tag>  ex.: v0.2.3 (vazio se ainda não houver tags -> v0.1.0)
#   <branch>      branch de origem do PR (vazio num push direto)
#
# Regras:
#   feat/*, feature/* -> sobe o MINOR (v0.2.3 -> v0.3.0)
#   tudo o resto  -> sobe o PATCH (v0.2.3 -> v0.2.4)
#   O MAJOR (ex.: v1.0.0 no fim do sprint B) é criado à mão; a pipeline
#   continua a partir dele.
set -euo pipefail

latest="${1:-}"
branch="${2:-}"

if [ -z "$latest" ]; then
  echo "v0.1.0"
  exit 0
fi

if ! [[ "$latest" =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  echo "Tag inválida: '$latest' (esperado vX.Y.Z)" >&2
  exit 1
fi

major="${BASH_REMATCH[1]}"
minor="${BASH_REMATCH[2]}"
patch="${BASH_REMATCH[3]}"

case "$branch" in
  feat/*|feature/*) echo "v${major}.$((minor + 1)).0" ;;
  *)      echo "v${major}.${minor}.$((patch + 1))" ;;
esac
