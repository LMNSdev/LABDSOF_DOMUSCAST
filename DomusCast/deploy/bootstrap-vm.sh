#!/usr/bin/env bash
# Prepara uma VM Ubuntu 24.04 acabada de criar para receber o DomusCast.
# Corre UMA vez, como azureuser (com sudo):
#
#   ssh -i ~/.ssh/domuscast_azure azureuser@<host> \
#     "sudo bash -s -- '<chave pública do deploy>'" < DomusCast/deploy/bootstrap-vm.sh
#
# O que faz:
#   1. Instala o Docker Engine e o plugin Compose (repositório oficial da Docker).
#   2. Cria o utilizador "deploy" (sem password, sem sudo), membro do grupo docker,
#      que só entra com a chave SSH usada pelo GitHub Actions.
#   3. Cria /opt/domuscast, a pasta onde ficam o compose de produção e o .env.
# É idempotente: pode voltar a correr sem estragar nada.
set -euo pipefail

DEPLOY_PUBKEY="${1:?Uso: bootstrap-vm.sh '<chave pública SSH do deploy>'}"
APP_DIR=/opt/domuscast

echo "==> Docker"
if ! command -v docker >/dev/null; then
  apt-get update -q
  apt-get install -y -q ca-certificates curl
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  . /etc/os-release
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update -q
  apt-get install -y -q docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi
systemctl enable --now docker

echo "==> Utilizador deploy"
if ! id deploy >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash deploy
fi
usermod -aG docker deploy
passwd -l deploy >/dev/null
install -d -m 0700 -o deploy -g deploy /home/deploy/.ssh
echo "$DEPLOY_PUBKEY" > /home/deploy/.ssh/authorized_keys
chown deploy:deploy /home/deploy/.ssh/authorized_keys
chmod 0600 /home/deploy/.ssh/authorized_keys

echo "==> Pasta da aplicação"
install -d -m 0750 -o deploy -g deploy "$APP_DIR"

echo "==> Pronto"
docker --version
docker compose version
