#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  tools/update_selected_tfvars.sh --target TARGET [--department DEPT] [--environment ENV] [--workload WORKLOAD] [--name NAME]

TARGET:
  foundation | hub-network | azure-firewall | workload | vm | aks | ai | nlb | alb | private-dns-zones

Examples:
  tools/update_selected_tfvars.sh --target workload --department Sales --environment dev
  tools/update_selected_tfvars.sh --target azure-firewall
  tools/update_selected_tfvars.sh --target vm --workload 영업지원 --environment dev
  tools/update_selected_tfvars.sh --target nlb --workload 영업지원 --environment dev
  tools/update_selected_tfvars.sh --target alb --workload 영업지원 --environment dev

This updates only selected live/**/terraform.tfvars files and prints Terraform roots to plan/apply.
USAGE
}

TARGET=""
DEPARTMENT=""
ENVIRONMENT=""
WORKLOAD=""
NAME=""
EXCEL="azure_landingzone_terraform_module_design.xlsx"
TENANT_ID="${TENANT_ID:-}"
SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --department) DEPARTMENT="$2"; shift 2 ;;
    --environment) ENVIRONMENT="$2"; shift 2 ;;
    --workload) WORKLOAD="$2"; shift 2 ;;
    --name) NAME="$2"; shift 2 ;;
    --excel) EXCEL="$2"; shift 2 ;;
    --tenant-id) TENANT_ID="$2"; shift 2 ;;
    --subscription-id) SUBSCRIPTION_ID="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  echo "--target is required" >&2
  usage
  exit 2
fi

case "$TARGET" in
  foundation|hub-network|azure-firewall|workload|vm|aks|ai|nlb|alb|private-dns-zones) ;;
  *) echo "Invalid --target: $TARGET" >&2; usage; exit 2 ;;
esac

if [[ -z "$TENANT_ID" || -z "$SUBSCRIPTION_ID" ]]; then
  echo "TENANT_ID and SUBSCRIPTION_ID are required. Use --tenant-id/--subscription-id or environment variables." >&2
  exit 2
fi

slug() {
  local v="${1,,}"
  v="${v//영업지원/sales}"
  v="${v//영업/sales}"
  v="${v//계약관리/policy}"
  v="${v//계약/policy}"
  v="${v//모바일api/digital}"
  v="${v//디지털/digital}"
  v="${v//상품/product}"
  v="${v//ai platform/ai}"
  v="${v//ai sandbox/ai}"
  v="$(echo "$v" | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
  [[ -n "$v" ]] && echo "$v" || echo "item"
}

TMP_OUT="$(mktemp -d /tmp/azlz_selected_tfvars.XXXXXX)"
trap 'rm -rf "$TMP_OUT"' EXIT

python3 tools/excel_to_tfvars.py \
  --excel "$EXCEL" \
  --out "$TMP_OUT" \
  --tenant-id "$TENANT_ID" \
  --subscription-id "$SUBSCRIPTION_ID" >/tmp/azlz_selected_tfvars.log

paths=()
case "$TARGET" in
  foundation)
    paths+=("00-foundation/resource-groups/terraform.tfvars")
    ;;
  hub-network)
    paths+=("10-platform/hub-network/terraform.tfvars")
    ;;
  azure-firewall)
    paths+=("10-platform/azure-firewall/terraform.tfvars")
    ;;
  private-dns-zones)
    paths+=("40-access/private-dns-zones/terraform.tfvars")
    ;;
  workload)
    if [[ -z "$DEPARTMENT" || -z "$ENVIRONMENT" ]]; then
      echo "workload target requires --department and --environment" >&2
      exit 2
    fi
    paths+=("20-workload/$(slug "$DEPARTMENT")-${ENVIRONMENT,,}-spoke/terraform.tfvars")
    ;;
  vm)
    if [[ -z "$WORKLOAD" || -z "$ENVIRONMENT" ]]; then
      echo "vm target requires --workload and --environment" >&2
      exit 2
    fi
    paths+=("30-services/vm-$(slug "$WORKLOAD")-${ENVIRONMENT,,}/terraform.tfvars")
    ;;
  aks)
    if [[ -z "$WORKLOAD" || -z "$ENVIRONMENT" ]]; then
      echo "aks target requires --workload and --environment" >&2
      exit 2
    fi
    paths+=("30-services/aks-$(slug "$WORKLOAD")-${ENVIRONMENT,,}/terraform.tfvars")
    ;;
  ai)
    if [[ -z "$DEPARTMENT" || -z "$ENVIRONMENT" ]]; then
      echo "ai target requires --department and --environment" >&2
      exit 2
    fi
    paths+=("30-services/ai-$(slug "$DEPARTMENT")-${ENVIRONMENT,,}/terraform.tfvars")
    ;;
  nlb)
    if [[ -z "$WORKLOAD" || -z "$ENVIRONMENT" ]]; then
      echo "nlb target requires --workload and --environment" >&2
      exit 2
    fi
    python3 tools/excel_to_lb_tfvars.py \
      --excel "$EXCEL" \
      --out "$TMP_OUT" \
      --target nlb \
      --workload "$WORKLOAD" \
      --environment "$ENVIRONMENT" >/tmp/azlz_selected_lb_tfvars.log
    paths+=("30-services/nlb-$(slug "$WORKLOAD")-${ENVIRONMENT,,}-web/terraform.tfvars")
    ;;
  alb)
    if [[ -z "$WORKLOAD" || -z "$ENVIRONMENT" ]]; then
      echo "alb target requires --workload and --environment" >&2
      exit 2
    fi
    python3 tools/excel_to_lb_tfvars.py \
      --excel "$EXCEL" \
      --out "$TMP_OUT" \
      --target alb \
      --workload "$WORKLOAD" \
      --environment "$ENVIRONMENT" >/tmp/azlz_selected_lb_tfvars.log
    paths+=("30-services/alb-$(slug "$WORKLOAD")-${ENVIRONMENT,,}-web/terraform.tfvars")
    ;;
esac

updated=()
for rel in "${paths[@]}"; do
  src="$TMP_OUT/$rel"
  dst="live/$rel"
  if [[ ! -f "$src" ]]; then
    echo "No generated tfvars for: $rel" >&2
    exit 1
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  terraform fmt "$dst" >/dev/null
  updated+=("$dst")
done

echo "Updated tfvars:"
printf ' - %s\n' "${updated[@]}"
echo
echo "Terraform roots to run:"
for f in "${updated[@]}"; do
  dirname "$f"
done | sort -u
