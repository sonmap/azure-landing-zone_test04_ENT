# Excel to tfvars 매핑표

Excel에서 어떤 값을 수정하면 어떤 `terraform.tfvars`가 바뀌는지 확인하는 표입니다. 같은 내용은 Excel의 `19_TFVars_Mapping` 시트에도 들어 있습니다.

| Excel 시트 | 식별 조건 | 생성 tfvars | 선택 갱신 명령 | Terraform root |
|---|---|---|---|---|
| `04_Workload_LZ` | `Sales`, `dev` | `live/20-workload/sales-dev-spoke/terraform.tfvars` | `tools/update_selected_tfvars.sh --target workload --department Sales --environment dev` | `live/20-workload/sales-dev-spoke` |
| `04_Workload_LZ` | `Sales`, `prod` | `live/20-workload/sales-prod-spoke/terraform.tfvars` | `tools/update_selected_tfvars.sh --target workload --department Sales --environment prod` | `live/20-workload/sales-prod-spoke` |
| `04_Workload_LZ` | `Policy`, `prod` | `live/20-workload/policy-prod-spoke/terraform.tfvars` | `tools/update_selected_tfvars.sh --target workload --department Policy --environment prod` | `live/20-workload/policy-prod-spoke` |
| `04_Workload_LZ` | `Digital`, `prod` | `live/20-workload/digital-prod-spoke/terraform.tfvars` | `tools/update_selected_tfvars.sh --target workload --department Digital --environment prod` | `live/20-workload/digital-prod-spoke` |
| `04_Workload_LZ` | `AI Platform`, `sandbox` | `live/20-workload/ai-sandbox-spoke/terraform.tfvars` | `tools/update_selected_tfvars.sh --target workload --department "AI Platform" --environment sandbox` | `live/20-workload/ai-sandbox-spoke` |
| `05_VM_Module` | `영업지원`, `dev` | `live/30-services/vm-sales-dev/terraform.tfvars` | `tools/update_selected_tfvars.sh --target vm --workload 영업지원 --environment dev` | `live/30-services/vm-sales-dev` |
| `05_VM_Module` | `계약관리`, `prod` | `live/30-services/vm-policy-prod/terraform.tfvars` | `tools/update_selected_tfvars.sh --target vm --workload 계약관리 --environment prod` | `live/30-services/vm-policy-prod` |
| `07_AKS_Module` | `모바일API`, `prod` | `live/30-services/aks-digital-prod/terraform.tfvars` | `tools/update_selected_tfvars.sh --target aks --workload 모바일API --environment prod` | `live/30-services/aks-digital-prod` |
| `07_AKS_Module` | `API`, `dev` | `live/30-services/aks-api-dev/terraform.tfvars` | `tools/update_selected_tfvars.sh --target aks --workload API --environment dev` | `live/30-services/aks-api-dev` |
| `07_AKS_Module` | `cron`, `prod` | `live/30-services/aks-cron-prod/terraform.tfvars` | `tools/update_selected_tfvars.sh --target aks --workload cron --environment prod` | `live/30-services/aks-cron-prod` |
| `08_AI_Private_Module` | `상품`, `sandbox` | `live/30-services/ai-product-sandbox/terraform.tfvars` | `tools/update_selected_tfvars.sh --target ai --department 상품 --environment sandbox` | `live/30-services/ai-product-sandbox` |
| `08_AI_Private_Module` | `영업`, `sandbox` | `live/30-services/ai-sales-sandbox/terraform.tfvars` | `tools/update_selected_tfvars.sh --target ai --department 영업 --environment sandbox` | `live/30-services/ai-sales-sandbox` |
| `20_LoadBalancer` | `LB Type=NLB`, `영업지원`, `dev` | `live/30-services/nlb-sales-dev-web/terraform.tfvars` | `tools/update_selected_tfvars.sh --target nlb --workload 영업지원 --environment dev` | `live/30-services/nlb-sales-dev-web` |
| `20_LoadBalancer` | `LB Type=ALB`, `영업지원`, `dev` | `live/30-services/alb-sales-dev-web/terraform.tfvars` | `tools/update_selected_tfvars.sh --target alb --workload 영업지원 --environment dev` | `live/30-services/alb-sales-dev-web` |
| `03_Network_Connectivity` | `구분=Azure Firewall` | `live/10-platform/azure-firewall/terraform.tfvars` | `tools/update_selected_tfvars.sh --target azure-firewall` | `live/10-platform/azure-firewall` |
| `03_Network_Connectivity` + CLI 기본값 | Hub Network | `live/10-platform/hub-network/terraform.tfvars` | `tools/update_selected_tfvars.sh --target hub-network` | `live/10-platform/hub-network` |
| `04_Workload_LZ` 전체 | Resource Group 목록 | `live/00-foundation/resource-groups/terraform.tfvars` | `tools/update_selected_tfvars.sh --target foundation` | `live/00-foundation/resource-groups` |
| Private DNS 표준값 | Private DNS Zone | `live/40-access/private-dns-zones/terraform.tfvars` | `tools/update_selected_tfvars.sh --target private-dns-zones` | `live/40-access/private-dns-zones` |

## 작업 순서

1. Excel에서 해당 시트/행 수정
2. 위 표의 선택 갱신 명령 실행
3. 출력된 Terraform root로 이동
4. `terraform plan` 확인
5. 필요할 때만 `terraform apply`
