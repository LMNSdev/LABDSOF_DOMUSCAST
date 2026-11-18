#!/usr/bin/env bash
# Implanta uma versão do DomusCast na VM. Corre em /opt/domuscast como "deploy":
#
#   bash deploy.sh v0.3.0
#
# Espera na mesma pasta: docker-compose.prod.yml e Caddyfile (copiados pela pipeline).
# No primeiro deploy cria o .env com uma password aleatória para o PostgreSQL;
# depois nunca a altera (o volume da base de dados já foi criado com ela).
# SKIP_PULL=1 usa uma imagem que já exista localmente (só para testes manuais).
set -euo pipefail

VERSION="${1:-}"
if ! [[ "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Versão inválida: '$VERSION' (esperado vX.Y.Z)" >&2
  exit 1
fi

cd "$(dirname "$0")"

if [ ! -f .env ]; then
  umask 077
  printf 'POSTGRES_PASSWORD=%s\n' "$(openssl rand -hex 24)" > .env
  echo "Criado .env com uma password nova para o PostgreSQL."
fi
chmod 600 .env

# A versão em uso também fica no .env, para que comandos manuais na VM
# (docker compose ps/logs/restart) funcionem sem indicar IMAGE_TAG.
sed -i '/^IMAGE_TAG=/d' .env
echo "IMAGE_TAG=$VERSION" >> .env

compose=(docker compose -f docker-compose.prod.yml)

if [ "${SKIP_PULL:-}" != "1" ]; then
  "${compose[@]}" pull
fi
"${compose[@]}" up -d --remove-orphans
# Apaga imagens que nenhum container usa (versões antigas da API), para o disco
# de 30 GB não encher; um rollback volta a descarregar a versão do GHCR.
docker image prune -af >/dev/null

echo "$VERSION" > VERSION
echo "DomusCast $VERSION em execução."
