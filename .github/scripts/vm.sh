#!/usr/bin/env bash
# Estado, ligar e desalocar a VM de produção (requer sessão "az" ativa).
#
# Uso: vm.sh status|start|deallocate
#   status      imprime o estado: running, deallocated, stopped, starting, deallocating...
#   start       liga a VM (não faz nada se já estiver ligada) e imprime o estado final
#   deallocate  desaloca a VM (deixa de cobrar computação) e imprime o estado final
#
# Grupo e VM sobreponíveis por AZ_RG / AZ_VM. Se AZURE_SUBSCRIPTION_ID estiver
# definido, é usado em todos os comandos.
set -euo pipefail

RG="${AZ_RG:-domuscast-rg}"
VM="${AZ_VM:-domuscast-vm}"
sub=()
if [ -n "${AZURE_SUBSCRIPTION_ID:-}" ]; then
  sub=(--subscription "$AZURE_SUBSCRIPTION_ID")
fi

estado() {
  az vm get-instance-view -g "$RG" -n "$VM" "${sub[@]}" \
    --query "instanceView.statuses[?starts_with(code, 'PowerState/')].code | [0]" -o tsv \
    | tr -d '\r' | sed 's#^PowerState/##'
}

case "${1:-}" in
  status)
    estado
    ;;
  start)
    [ "$(estado)" = running ] || az vm start -g "$RG" -n "$VM" "${sub[@]}" -o none
    estado
    ;;
  deallocate)
    [ "$(estado)" = deallocated ] || az vm deallocate -g "$RG" -n "$VM" "${sub[@]}" -o none
    estado
    ;;
  *)
    echo "Uso: $0 status|start|deallocate" >&2
    exit 2
    ;;
esac
