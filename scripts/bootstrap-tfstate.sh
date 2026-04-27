#!/usr/bin/env bash

set -euo pipefail

RESOURCE_GROUP_NAME="${RESOURCE_GROUP_NAME:-rg-autopack-tfstate}"
LOCATION="${LOCATION:-westeurope}"
CONTAINER_NAME="${CONTAINER_NAME:-tfstate}"
SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-$(az account show --query id -o tsv)}"
SUBSCRIPTION_HASH="$(printf '%s' "${SUBSCRIPTION_ID}" | tr -d '-' | cut -c1-12)"
STORAGE_ACCOUNT_NAME="${STORAGE_ACCOUNT_NAME:-aptfstate${SUBSCRIPTION_HASH}}"
BACKEND_BLOB_DATA_CONTRIBUTOR_PRINCIPAL_IDS="${BACKEND_BLOB_DATA_CONTRIBUTOR_PRINCIPAL_IDS:-}"

echo "Using subscription: ${SUBSCRIPTION_ID}"
echo "Ensuring Terraform backend resource group: ${RESOURCE_GROUP_NAME}"
echo "Storage account: ${STORAGE_ACCOUNT_NAME}"
echo "Container: ${CONTAINER_NAME}"

az account set --subscription "${SUBSCRIPTION_ID}"

az group create \
  --name "${RESOURCE_GROUP_NAME}" \
  --location "${LOCATION}" \
  --output none

az storage account create \
  --name "${STORAGE_ACCOUNT_NAME}" \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --location "${LOCATION}" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --output none

az storage container create \
  --name "${CONTAINER_NAME}" \
  --account-name "${STORAGE_ACCOUNT_NAME}" \
  --auth-mode login \
  --output none

STORAGE_ACCOUNT_SCOPE="$(az storage account show \
  --name "${STORAGE_ACCOUNT_NAME}" \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --query id \
  --output tsv)"

if [[ -n "${BACKEND_BLOB_DATA_CONTRIBUTOR_PRINCIPAL_IDS}" ]]; then
  IFS=',' read -r -a PRINCIPAL_IDS <<< "${BACKEND_BLOB_DATA_CONTRIBUTOR_PRINCIPAL_IDS}"

  for raw_principal_id in "${PRINCIPAL_IDS[@]}"; do
    principal_id="$(printf '%s' "${raw_principal_id}" | xargs)"

    if [[ -z "${principal_id}" ]]; then
      continue
    fi

    existing_assignment_count="$(az role assignment list \
      --assignee-object-id "${principal_id}" \
      --role "Storage Blob Data Contributor" \
      --scope "${STORAGE_ACCOUNT_SCOPE}" \
      --query 'length(@)' \
      --output tsv)"

    if [[ "${existing_assignment_count}" == "0" ]]; then
      az role assignment create \
        --assignee-object-id "${principal_id}" \
        --assignee-principal-type ServicePrincipal \
        --role "Storage Blob Data Contributor" \
        --scope "${STORAGE_ACCOUNT_SCOPE}" \
        --output none
    fi
  done
fi

cat <<EOF

Terraform backend bootstrap complete.

GitHub repository variables:
  TFSTATE_RESOURCE_GROUP_NAME=${RESOURCE_GROUP_NAME}
  TFSTATE_STORAGE_ACCOUNT_NAME=${STORAGE_ACCOUNT_NAME}
  TFSTATE_CONTAINER_NAME=${CONTAINER_NAME}

Local init example for dev:
  terraform -chdir=infra init \
    -backend-config="resource_group_name=${RESOURCE_GROUP_NAME}" \
    -backend-config="storage_account_name=${STORAGE_ACCOUNT_NAME}" \
    -backend-config="container_name=${CONTAINER_NAME}" \
    -backend-config="key=autopack-dev.tfstate"

EOF
