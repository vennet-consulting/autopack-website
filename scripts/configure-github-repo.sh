#!/usr/bin/env bash

set -euo pipefail

REPO="${REPO:-vennet-consulting/autopack-website}"
IDENTITY_RESOURCE_GROUP_NAME="${IDENTITY_RESOURCE_GROUP_NAME:-rg-autopack-tfstate}"
IDENTITY_NAME="${IDENTITY_NAME:-autopack-gha}"
TFSTATE_RESOURCE_GROUP_NAME="${TFSTATE_RESOURCE_GROUP_NAME:-rg-autopack-tfstate}"
SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID:-$(az account show --query id -o tsv)}"
TENANT_ID="${AZURE_TENANT_ID:-$(az account show --query tenantId -o tsv)}"
SUBSCRIPTION_HASH="$(printf '%s' "${SUBSCRIPTION_ID}" | tr -d '-' | cut -c1-12)"
TFSTATE_STORAGE_ACCOUNT_NAME="${TFSTATE_STORAGE_ACCOUNT_NAME:-aptfstate${SUBSCRIPTION_HASH}}"
TFSTATE_CONTAINER_NAME="${TFSTATE_CONTAINER_NAME:-tfstate}"
AZURE_CLIENT_ID="${AZURE_CLIENT_ID:-$(az identity show --name "${IDENTITY_NAME}" --resource-group "${IDENTITY_RESOURCE_GROUP_NAME}" --query clientId -o tsv)}"

gh repo view "${REPO}" >/dev/null

for environment_name in dev prod; do
  gh api \
    --method PUT \
    -H "Accept: application/vnd.github+json" \
    "/repos/${REPO}/environments/${environment_name}" \
    >/dev/null
done

gh variable set TFSTATE_RESOURCE_GROUP_NAME --repo "${REPO}" --body "${TFSTATE_RESOURCE_GROUP_NAME}"
gh variable set TFSTATE_STORAGE_ACCOUNT_NAME --repo "${REPO}" --body "${TFSTATE_STORAGE_ACCOUNT_NAME}"
gh variable set TFSTATE_CONTAINER_NAME --repo "${REPO}" --body "${TFSTATE_CONTAINER_NAME}"

gh secret set AZURE_CLIENT_ID --repo "${REPO}" --body "${AZURE_CLIENT_ID}"
gh secret set AZURE_TENANT_ID --repo "${REPO}" --body "${TENANT_ID}"
gh secret set AZURE_SUBSCRIPTION_ID --repo "${REPO}" --body "${SUBSCRIPTION_ID}"

cat <<EOF

GitHub repository configuration complete.

Repository: ${REPO}
Environments: dev, prod
Variables:
  TFSTATE_RESOURCE_GROUP_NAME=${TFSTATE_RESOURCE_GROUP_NAME}
  TFSTATE_STORAGE_ACCOUNT_NAME=${TFSTATE_STORAGE_ACCOUNT_NAME}
  TFSTATE_CONTAINER_NAME=${TFSTATE_CONTAINER_NAME}

Secrets:
  AZURE_CLIENT_ID
  AZURE_TENANT_ID
  AZURE_SUBSCRIPTION_ID

EOF
