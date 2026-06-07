#!/usr/bin/env bash
set -u

REPO_ROOT="/home/son/azure_land06"
cd "$REPO_ROOT" || exit 1

LOG_FILE="$REPO_ROOT/logs/destroy-after-ttl.log"

{
  echo "==== TTL destroy started: $(date -Is) ===="
  az account show --query "{user:user.name,tenantId:tenantId,subscriptionId:id,name:name}" -o json || true

  fixed_roots=(
    live/40-access/firewall-rule
    live/40-access/dns-record
    live/40-access/private-endpoint
    live/40-access/private-dns-zones
    live/30-services/containerapp-sales-dev
    live/30-services/containerapp-ai-sandbox
    live/30-services/alb-sales-dev-web
    live/30-services/nlb-sales-dev-web
    live/30-services/monitoring-sales-dev
    live/30-services/monitoring-dashboard-sales-dev
    live/30-services/metric-alert-sales-dev
    live/30-services/action-group-sales-dev
    live/30-services/waf-sales-dev
    live/30-services/backup-sales-dev
    live/30-services/kms-sales-dev
    live/30-services/identity-sales-dev
    live/30-services/ai-sales-sandbox
    live/30-services/ai-product-sandbox
    live/30-services/aks-sales-dev
    live/30-services/aks-digital-prod
    live/30-services/aks-api-dev
    live/30-services/aks-cron-prod
    live/30-services/webwas-sales-dev
    live/30-services/vm-sales-dev
    live/30-services/vm-policy-prod
    live/30-services/vm-item-prod
    live/10-platform/azure-firewall
    live/10-platform/ddos
    live/10-platform/monitoring
    live/10-platform/monitoring-dashboard
    live/10-platform/action-group
    live/20-workload/ai-sandbox-spoke
    live/20-workload/digital-prod-spoke
    live/20-workload/policy-prod-spoke
    live/20-workload/sales-prod-spoke
    live/20-workload/sales-dev-spoke
    live/10-platform/hub-network
    live/00-foundation/policy
    live/00-foundation/iam-rbac
    live/00-foundation/resource-groups
  )

  declare -A seen=()
  for root in "${fixed_roots[@]}"; do
    seen["$root"]=1
    if [[ "$root" == *"-prod"* || "$root" == *"/prod"* ]]; then
      echo "---- skip $root: production root protected ----"
      continue
    fi
    if [[ -f "$root/terraform.tfvars" || -f "$root/main.tf" ]]; then
      echo "---- destroy $root ----"
      tools/tf_root.sh "$root" destroy || echo "WARN: destroy failed for $root"
    else
      echo "---- skip $root: no terraform root ----"
    fi
  done

  while IFS= read -r tfvars; do
    root="${tfvars%/terraform.tfvars}"
    [[ -n "${seen[$root]:-}" ]] && continue
    if [[ "$root" == *"-prod"* || "$root" == *"/prod"* ]]; then
      echo "---- skip discovered $root: production root protected ----"
      continue
    fi
    echo "---- destroy discovered $root ----"
    tools/tf_root.sh "$root" destroy || echo "WARN: destroy failed for $root"
  done < <(find live -name terraform.tfvars | sort -r)

  echo "==== TTL destroy finished: $(date -Is) ===="
  df -h /home || true
} >> "$LOG_FILE" 2>&1
