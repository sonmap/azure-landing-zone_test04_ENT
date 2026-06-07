#!/usr/bin/env bash
set -u
cd /home/son/azure_land06
{
  echo "==== destroy started: $(date -Is) ===="
  az account show --query "{user:user.name,tenantId:tenantId,subscriptionId:id,name:name}" -o json || true
  roots=(
    live/40-access/private-dns-zones
    live/40-access/firewall-rule
    live/40-access/dns-record
    live/40-access/private-endpoint
    live/30-services/ai-sales-sandbox
    live/30-services/aks-sales-dev
    live/30-services/webwas-sales-dev
    live/30-services/vm-sales-dev
    live/10-platform/azure-firewall
    live/20-workload/sales-dev-spoke
    live/10-platform/hub-network
    live/00-foundation/resource-groups
  )
  for root in "${roots[@]}"; do
    if [ -f "$root/terraform.tfvars" ]; then
      echo "---- destroy $root ----"
      tools/tf_root.sh "$root" destroy || echo "WARN: destroy failed for $root"
    else
      echo "---- skip $root: no terraform.tfvars ----"
    fi
  done
  echo "==== destroy finished: $(date -Is) ===="
  df -h /home
} >> /home/son/azure_land06/logs/destroy-after-1h.log 2>&1
