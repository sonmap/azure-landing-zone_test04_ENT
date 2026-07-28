#!/usr/bin/env bash
set -euo pipefail

lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Required environment variable is empty: $name" >&2
    exit 2
  fi
}

for name in \
  ARM_SUBSCRIPTION_ID \
  TFSTATE_RESOURCE_GROUP \
  TFSTATE_STORAGE_ACCOUNT \
  TFSTATE_CONTAINER; do
  require_env "$name"
done

TFSTATE_LOCATION="${TFSTATE_LOCATION:-koreacentral}"
BOOTSTRAP_CREATE="$(lower "${BOOTSTRAP_CREATE:-true}")"
GRANT_BACKEND_ROLE="$(lower "${GRANT_BACKEND_ROLE:-true}")"

if [[ ! "$TFSTATE_STORAGE_ACCOUNT" =~ ^[a-z0-9]{3,24}$ ]]; then
  echo "TFSTATE_STORAGE_ACCOUNT must contain 3-24 lowercase letters or numbers." >&2
  exit 2
fi

if [[ ! "$TFSTATE_CONTAINER" =~ ^[a-z0-9]([a-z0-9-]{1,61}[a-z0-9])?$ ]]; then
  echo "TFSTATE_CONTAINER must be a valid lowercase Azure Blob container name." >&2
  exit 2
fi

az account set --subscription "$ARM_SUBSCRIPTION_ID"

principal_object_id="$(
  az account get-access-token \
    --resource https://management.azure.com/ \
    --query accessToken \
    --output tsv \
  | python3 -c '
import base64
import json
import sys

token = sys.stdin.read().strip()
parts = token.split(".")
if len(parts) < 2:
    raise SystemExit("Azure access token is not a JWT")
payload = parts[1] + "=" * (-len(parts[1]) % 4)
claims = json.loads(base64.urlsafe_b64decode(payload.encode()).decode())
oid = claims.get("oid")
if not oid:
    raise SystemExit("Azure access token does not contain an oid claim")
print(oid)
'
)"

if [[ -z "$principal_object_id" ]]; then
  echo "Could not determine the Azure Service Connection principal object ID." >&2
  exit 2
fi

echo "Terraform backend configuration"
echo "  subscription: $ARM_SUBSCRIPTION_ID"
echo "  resource group: $TFSTATE_RESOURCE_GROUP"
echo "  storage account: $TFSTATE_STORAGE_ACCOUNT"
echo "  container: $TFSTATE_CONTAINER"
echo "  location: $TFSTATE_LOCATION"
echo "  create missing resources: $BOOTSTRAP_CREATE"
echo "  grant backend role: $GRANT_BACKEND_ROLE"
echo "  service connection object ID: $principal_object_id"

if ! az group show --name "$TFSTATE_RESOURCE_GROUP" >/dev/null 2>&1; then
  if [[ "$BOOTSTRAP_CREATE" != "true" ]]; then
    echo "Terraform backend resource group does not exist." >&2
    exit 3
  fi

  echo "Creating resource group: $TFSTATE_RESOURCE_GROUP"
  az group create \
    --name "$TFSTATE_RESOURCE_GROUP" \
    --location "$TFSTATE_LOCATION" \
    --tags managed-by=azure-devops purpose=terraform-state \
    --output none
else
  echo "Resource group already exists."
fi

if ! az storage account show \
  --resource-group "$TFSTATE_RESOURCE_GROUP" \
  --name "$TFSTATE_STORAGE_ACCOUNT" >/dev/null 2>&1; then

  if [[ "$BOOTSTRAP_CREATE" != "true" ]]; then
    echo "Terraform backend storage account does not exist." >&2
    exit 3
  fi

  echo "Creating storage account: $TFSTATE_STORAGE_ACCOUNT"
  az storage account create \
    --resource-group "$TFSTATE_RESOURCE_GROUP" \
    --name "$TFSTATE_STORAGE_ACCOUNT" \
    --location "$TFSTATE_LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --https-only true \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    --allow-shared-key-access false \
    --public-network-access Enabled \
    --tags managed-by=azure-devops purpose=terraform-state \
    --output none
else
  echo "Storage account already exists."
fi

storage_id="$(az storage account show \
  --resource-group "$TFSTATE_RESOURCE_GROUP" \
  --name "$TFSTATE_STORAGE_ACCOUNT" \
  --query id \
  --output tsv)"

container_url="https://management.azure.com${storage_id}/blobServices/default/containers/${TFSTATE_CONTAINER}?api-version=2023-05-01"

if ! az rest --method get --url "$container_url" >/dev/null 2>&1; then
  if [[ "$BOOTSTRAP_CREATE" != "true" ]]; then
    echo "Terraform backend container does not exist." >&2
    exit 3
  fi

  echo "Creating private blob container: $TFSTATE_CONTAINER"
  az rest \
    --method put \
    --url "$container_url" \
    --body '{"properties":{"publicAccess":"None"}}' \
    --output none
else
  echo "Blob container already exists."
fi

role_name="Storage Blob Data Contributor"

if [[ "$GRANT_BACKEND_ROLE" == "true" ]]; then
  role_count="$(
    az role assignment list \
      --assignee-object-id "$principal_object_id" \
      --fill-principal-name false \
      --scope "$storage_id" \
      --include-inherited \
      --role "$role_name" \
      --query 'length(@)' \
      --output tsv 2>/dev/null || printf '0'
  )"

  if [[ "$role_count" == "0" ]]; then
    echo "Granting '$role_name' to service connection identity."
    role_output="$(
      az role assignment create \
        --assignee-object-id "$principal_object_id" \
        --assignee-principal-type ServicePrincipal \
        --role "$role_name" \
        --scope "$storage_id" \
        --output none 2>&1
    )" || {
      if grep -qi 'RoleAssignmentExists' <<<"$role_output"; then
        echo "Role assignment already exists."
      else
        echo "$role_output" >&2
        echo "The service connection needs Owner, User Access Administrator, or Role Based Access Control Administrator to create the backend role assignment." >&2
        exit 4
      fi
    }
  else
    echo "Required data-plane role is already assigned."
  fi
fi

echo "Verifying Microsoft Entra access to the backend container."
verified="false"
for attempt in $(seq 1 18); do
  if az storage container show \
    --name "$TFSTATE_CONTAINER" \
    --account-name "$TFSTATE_STORAGE_ACCOUNT" \
    --auth-mode login \
    --output none >/dev/null 2>&1; then
    verified="true"
    break
  fi

  echo "Waiting for Storage RBAC propagation ($attempt/18)..."
  sleep 10
done

if [[ "$verified" != "true" ]]; then
  echo "The backend exists, but the service connection cannot access Blob data with Microsoft Entra authentication." >&2
  echo "Assign '$role_name' on storage account '$TFSTATE_STORAGE_ACCOUNT' and rerun the pipeline." >&2
  exit 5
fi

echo "Terraform backend is ready."
