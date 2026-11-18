#!/usr/bin/env bash
# Login na Azure a partir do GitHub Actions, por OIDC e sem passwords.
#
# O GitHub emite um token de curta duração para este job; a Azure aceita-o
# porque a identidade domuscast-github-deploy confia em
# repo:LMNSdev/LABDSOF_DOMUSCAST:environment:production (ver docs/sprintB/VM).
# Requer no job: environment: production e permissions: id-token: write.
set -euo pipefail

: "${AZURE_CLIENT_ID:?falta a variável AZURE_CLIENT_ID (environment production)}"
: "${AZURE_TENANT_ID:?falta a variável AZURE_TENANT_ID (environment production)}"
: "${ACTIONS_ID_TOKEN_REQUEST_URL:?o job precisa de permissions: id-token: write}"

token=$(curl -fsS -H "Authorization: Bearer ${ACTIONS_ID_TOKEN_REQUEST_TOKEN}" \
  "${ACTIONS_ID_TOKEN_REQUEST_URL}&audience=api://AzureADTokenExchange" | jq -r .value)
echo "::add-mask::${token}"

# A identidade só tem permissões sobre a VM, por isso pode não "ver" a subscrição;
# os comandos seguintes indicam-na com --subscription (ver vm.sh).
az login --service-principal -u "$AZURE_CLIENT_ID" -t "$AZURE_TENANT_ID" \
  --federated-token "$token" --allow-no-subscriptions -o none
echo "Login na Azure feito como ${AZURE_CLIENT_ID}."
