# Azure 전체 자원 리스트 확인법

## Azure CLI 기준

로그인 및 구독 확인:

```bash
az account show -o table
az account set --subscription <SUBSCRIPTION_ID>
```

구독 전체 자원:

```bash
az resource list \
  --query "[].{resourceGroup:resourceGroup,name:name,type:type,location:location}" \
  -o table
```

Resource Group별 자원:

```bash
az resource list -g rg-sl-hub-krc -o table
az resource list -g rg-sl-sales-dev -o table
az resource list -g rg-sl-sales-ai-sandbox -o table
```

태그와 Resource ID까지 포함:

```bash
az resource list \
  --query "[].{resourceGroup:resourceGroup,name:name,type:type,location:location,id:id,tags:tags}" \
  -o json
```

Azure Resource Graph 사용:

```bash
az graph query -q "Resources | project resourceGroup, name, type, location, id | order by resourceGroup asc, name asc" -o table
```

생성 시간 기준 정렬:

```bash
az graph query -q "Resources | project resourceGroup, name, type, location, createdTime=tostring(properties.timeCreated), id | order by createdTime desc" -o table
```

## Terraform State 기준

각 Terraform root에서:

```bash
terraform state list
terraform state show <resource_address>
```

원격 서버에서 전체 root를 순회하려면:

```bash
cd /home/son/azure_land06
for d in \
  live/00-foundation/resource-groups \
  live/10-platform/hub-network \
  live/10-platform/azure-firewall \
  live/20-workload/sales-dev-spoke \
  live/30-services/vm-sales-dev \
  live/30-services/aks-sales-dev \
  live/30-services/ai-sales-sandbox \
  live/40-access/private-dns-zones \
  live/40-access/private-endpoint \
  live/40-access/dns-record \
  live/40-access/firewall-rule
do
  echo "## $d"
  terraform -chdir="$d" state list || true
done
```

## 현재 작업에서 만든 주요 Resource Group

```bash
az resource list -g rg-sl-hub-krc -o table
az resource list -g rg-sl-sales-dev -o table
az resource list -g rg-sl-sales-ai-sandbox -o table
```

## 비용 확인 보조 명령

```bash
az consumption usage list \
  --query "[].{name:instanceName,meter:meterDetails.meterName,pretaxCost:pretaxCost,currency:currency}" \
  -o table
```

비용 API는 청구 권한과 EA/MCA 계약 유형에 따라 결과가 제한될 수 있다.
