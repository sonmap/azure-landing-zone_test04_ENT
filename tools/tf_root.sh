#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <terraform-root-dir> <validate|plan|apply|destroy> [plan-file]" >&2
  exit 2
fi

ROOT_DIR="${1%/}"
ACTION="$2"
PLAN_FILE="${3:-tfplan}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ABS_ROOT="$(cd "$REPO_ROOT/$ROOT_DIR" && pwd)"
BACKEND_CONFIG="${TF_BACKEND_CONFIG:-$REPO_ROOT/backend.hcl}"
STATE_KEY="${TF_STATE_KEY:-${ROOT_DIR}.tfstate}"
export TF_PLUGIN_CACHE_DIR="${TF_PLUGIN_CACHE_DIR:-$REPO_ROOT/.terraform.d/plugin-cache}"
export ARM_STORAGE_USE_AZUREAD="${ARM_STORAGE_USE_AZUREAD:-true}"

mkdir -p "$TF_PLUGIN_CACHE_DIR"

cd "$ABS_ROOT"

is_prod_root() {
  [[ "$ROOT_DIR" == *"-prod"* ]] && return 0
  [[ "$ROOT_DIR" == *"/prod"* ]] && return 0
  if [[ -f terraform.tfvars ]] && grep -Eiq '(^|[[:space:]])(env|environment)[[:space:]]*=[[:space:]]*"prod"' terraform.tfvars; then
    return 0
  fi
  if [[ -f terraform.tfvars ]] && grep -Eiq '(^|[[:space:]])env[[:space:]]*=[[:space:]]*"prod"' terraform.tfvars; then
    return 0
  fi
  return 1
}

case "$ACTION" in
  validate)
    terraform init -backend=false -input=false
    terraform validate
    ;;
  plan)
    if [[ ! -f "$BACKEND_CONFIG" ]]; then
      echo "Missing backend config: $BACKEND_CONFIG" >&2
      echo "Copy backend.hcl.example to backend.hcl and set the tfstate storage account values." >&2
      exit 1
    fi
    if [[ ! -f terraform.tfvars ]]; then
      echo "Missing $ABS_ROOT/terraform.tfvars" >&2
      echo "Copy terraform.tfvars.example to terraform.tfvars and set tenant/subscription/site values." >&2
      exit 1
    fi
    terraform init -reconfigure -input=false \
      -backend-config="$BACKEND_CONFIG" \
      -backend-config="key=$STATE_KEY"
    terraform plan -input=false -out="$PLAN_FILE"
    ;;
  apply)
    if [[ ! -f "$PLAN_FILE" ]]; then
      echo "Missing plan file: $ABS_ROOT/$PLAN_FILE" >&2
      echo "Run plan first, then apply the reviewed plan file." >&2
      exit 1
    fi
    terraform apply -input=false "$PLAN_FILE"
    if [[ "${TF_AUTO_DESTROY_ENABLED:-true}" == "true" ]]; then
      "$REPO_ROOT/tools/schedule_destroy_all.sh" "${TF_AUTO_DESTROY_AFTER_SECONDS:-3600}"
    fi
    ;;
  destroy)
    if is_prod_root && [[ "${ALLOW_PROD_DESTROY:-false}" != "true" ]]; then
      echo "BLOCKED: production Terraform root cannot be destroyed." >&2
      echo "root=$ROOT_DIR" >&2
      echo "To override intentionally, set ALLOW_PROD_DESTROY=true." >&2
      exit 10
    fi
    if [[ ! -f "$BACKEND_CONFIG" ]]; then
      echo "Missing backend config: $BACKEND_CONFIG" >&2
      exit 1
    fi
    terraform init -reconfigure -input=false \
      -backend-config="$BACKEND_CONFIG" \
      -backend-config="key=$STATE_KEY"
    terraform destroy -input=false -auto-approve
    ;;
  *)
    echo "Unknown action: $ACTION" >&2
    exit 2
    ;;
esac
