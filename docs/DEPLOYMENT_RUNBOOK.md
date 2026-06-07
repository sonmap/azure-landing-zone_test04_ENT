# Terraform Deployment Runbook

## 1. Confirm Azure login

```bash
az account show --query '{user:user.name, tenantId:tenantId, subscriptionId:id, name:name}' -o table
```

Current verified remote account:

- User: `<USER_EMAIL>`
- Tenant ID: `<TENANT_ID>`
- Subscription ID: `<SUBSCRIPTION_ID>`

## 2. Create Terraform state storage

Run once before real `plan/apply`.

```bash
az group create \
  --name <TFSTATE_RESOURCE_GROUP> \
  --location koreacentral

az storage account create \
  --name stslztfstate001 \
  --resource-group <TFSTATE_RESOURCE_GROUP> \
  --location koreacentral \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false

az storage container create \
  --name tfstate \
  --account-name stslztfstate001 \
  --auth-mode login
```

Storage account names are globally unique. Change `stslztfstate001` if Azure rejects it.

## 3. Configure backend

```bash
cd /home/son/azure_land06
cp backend.hcl.example backend.hcl
vi backend.hcl
```

Set the actual state storage values. `backend.hcl` is intentionally ignored by git.

## 4. Configure root module inputs

For each root module, copy the example file and replace tenant/subscription plus site-specific names, CIDRs, subnet IDs, DNS zone IDs, and SSH keys.

```bash
cd /home/son/azure_land06/live/00-foundation/resource-groups
cp terraform.tfvars.example terraform.tfvars
```

At minimum for the verified subscription:

```hcl
tenant_id       = "<TENANT_ID>"
subscription_id = "<SUBSCRIPTION_ID>"
```

## 5. Validate all root modules

```bash
cd /home/son/azure_land06
for d in \
  live/00-foundation/resource-groups \
  live/10-platform/hub-network \
  live/20-workload/sales-dev-spoke \
  live/30-services/vm-sales-dev \
  live/30-services/webwas-sales-dev \
  live/30-services/aks-sales-dev \
  live/30-services/ai-sales-sandbox \
  live/40-access/private-endpoint \
  live/40-access/dns-record \
  live/40-access/firewall-rule
do
  tools/tf_root.sh "$d" validate
done
```

## 6. Recommended apply order

Run `plan`, review it, then run `apply`.

```bash
tools/tf_root.sh live/00-foundation/resource-groups plan
tools/tf_root.sh live/00-foundation/resource-groups apply

tools/tf_root.sh live/10-platform/hub-network plan
tools/tf_root.sh live/10-platform/hub-network apply

tools/tf_root.sh live/20-workload/sales-dev-spoke plan
tools/tf_root.sh live/20-workload/sales-dev-spoke apply
```

Then deploy service modules only after subnet IDs, private DNS zone IDs, firewall policy IDs, and SSH keys are confirmed:

```bash
tools/tf_root.sh live/30-services/vm-sales-dev plan
tools/tf_root.sh live/30-services/webwas-sales-dev plan
tools/tf_root.sh live/30-services/aks-sales-dev plan
tools/tf_root.sh live/30-services/ai-sales-sandbox plan
tools/tf_root.sh live/40-access/private-endpoint plan
tools/tf_root.sh live/40-access/dns-record plan
tools/tf_root.sh live/40-access/firewall-rule plan
```

## 7. Guardrails before apply

- Do not apply from `terraform.tfvars.example`.
- Do not use local state for shared work.
- Confirm the selected subscription before every production apply.
- Keep `Public IP` and public network access disabled unless an approved exception exists.
- Run `terraform plan` and review created/changed/destroyed resources before `apply`.
