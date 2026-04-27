#!/usr/bin/env bash

set -euo pipefail

REPO="${REPO:-vennet-consulting/autopack-website}"
GITHUB_ORG="${REPO%%/*}"
GITHUB_REPO="${REPO##*/}"
IDENTITY_RESOURCE_GROUP_NAME="${IDENTITY_RESOURCE_GROUP_NAME:-rg-autopack-tfstate}"
IDENTITY_NAME="${IDENTITY_NAME:-autopack-gha}"
LOCATION="${LOCATION:-westeurope}"
SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-$(az account show --query id -o tsv)}"
SUBSCRIPTION_HASH="$(printf '%s' "${SUBSCRIPTION_ID}" | tr -d '-' | cut -c1-12)"
STORAGE_ACCOUNT_NAME="${STORAGE_ACCOUNT_NAME:-aptfstate${SUBSCRIPTION_HASH}}"

echo "Bootstrapping GitHub OIDC for ${REPO}"
echo "Identity resource group: ${IDENTITY_RESOURCE_GROUP_NAME}"
echo "Identity name: ${IDENTITY_NAME}"

az account set --subscription "${SUBSCRIPTION_ID}"

az group create \
  --name "${IDENTITY_RESOURCE_GROUP_NAME}" \
  --location "${LOCATION}" \
  --output none

if ! az identity show --name "${IDENTITY_NAME}" --resource-group "${IDENTITY_RESOURCE_GROUP_NAME}" --output none 2>/dev/null; then
  az identity create \
    --name "${IDENTITY_NAME}" \
    --resource-group "${IDENTITY_RESOURCE_GROUP_NAME}" \
    --location "${LOCATION}" \
    --output none
fi

CLIENT_ID="$(az identity show --name "${IDENTITY_NAME}" --resource-group "${IDENTITY_RESOURCE_GROUP_NAME}" --query clientId -o tsv)"
PRINCIPAL_ID="$(az identity show --name "${IDENTITY_NAME}" --resource-group "${IDENTITY_RESOURCE_GROUP_NAME}" --query principalId -o tsv)"
TENANT_ID="$(az account show --query tenantId -o tsv)"
SUBSCRIPTION_SCOPE="/subscriptions/${SUBSCRIPTION_ID}"
STORAGE_ACCOUNT_SCOPE="$(az storage account show --name "${STORAGE_ACCOUNT_NAME}" --resource-group "${IDENTITY_RESOURCE_GROUP_NAME}" --query id -o tsv)"

ensure_federated_credential() {
  local fic_name="$1"
  local fic_subject="$2"
  local existing_count

  existing_count="$(az identity federated-credential list \
    --identity-name "${IDENTITY_NAME}" \
    --resource-group "${IDENTITY_RESOURCE_GROUP_NAME}" \
    --query "[?name=='${fic_name}'] | length(@)" \
    -o tsv)"

  if [[ "${existing_count}" == "0" ]]; then
    az identity federated-credential create \
      --identity-name "${IDENTITY_NAME}" \
      --resource-group "${IDENTITY_RESOURCE_GROUP_NAME}" \
      --name "${fic_name}" \
      --issuer "https://token.actions.githubusercontent.com" \
      --subject "${fic_subject}" \
      --audiences "api://AzureADTokenExchange" \
      --output none
  fi
}

ensure_role_assignment() {
  local scope="$1"
  local role_name="$2"
  local existing_count

  existing_count="$(az role assignment list \
    --assignee-object-id "${PRINCIPAL_ID}" \
    --role "${role_name}" \
    --scope "${scope}" \
    --query 'length(@)' \
    -o tsv)"

  if [[ "${existing_count}" == "0" ]]; then
    az role assignment create \
      --assignee-object-id "${PRINCIPAL_ID}" \
      --assignee-principal-type ServicePrincipal \
      --role "${role_name}" \
      --scope "${scope}" \
      --output none
  fi
}

ensure_federated_credential "gh-main" "repo:${GITHUB_ORG}/${GITHUB_REPO}:ref:refs/heads/main"
ensure_federated_credential "gh-env-dev" "repo:${GITHUB_ORG}/${GITHUB_REPO}:environment:dev"
ensure_federated_credential "gh-env-prod" "repo:${GITHUB_ORG}/${GITHUB_REPO}:environment:prod"

ensure_role_assignment "${SUBSCRIPTION_SCOPE}" "Contributor"
ensure_role_assignment "${STORAGE_ACCOUNT_SCOPE}" "Storage Blob Data Contributor"

cat <<EOF

GitHub OIDC bootstrap complete.

GitHub repository secrets:
  AZURE_CLIENT_ID=${CLIENT_ID}
  AZURE_TENANT_ID=${TENANT_ID}
  AZURE_SUBSCRIPTION_ID=${SUBSCRIPTION_ID}

EOF
