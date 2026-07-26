# Excel Source of Truth → Terraform auto tfvars

이 구조에서는 Excel이 최초 설계 및 변경 관리의 원본(Source of Truth)입니다. `10-design.auto.tfvars.json`은 사람이 직접 수정하지 않고 Excel에서 다시 생성합니다.

## 파일 역할

```text
design/azure_landingzone_design.xlsx       설계 원본(로컬/사내 보관)
generated_tfvars/**/10-design.auto.tfvars.json  검토용 생성 결과
live/**/10-design.auto.tfvars.json         Terraform 실행 입력
variables.tf                               Terraform 입력 계약
main.tf                                    리소스 생성 로직
```

실제 `.xlsx`와 `*.auto.tfvars.json`은 현재 `.gitignore` 정책상 저장소에 커밋하지 않습니다. 공개 저장소에는 생성 스크립트와 문서만 보관합니다.

## 1. Excel 설계서 생성

Windows PowerShell:

```powershell
python .\tools\create_design_excel.py `
  --out .\design\azure_landingzone_design.xlsx
```

기존 파일을 다시 만들려면:

```powershell
python .\tools\create_design_excel.py `
  --out .\design\azure_landingzone_design.xlsx `
  --force
```

Linux:

```bash
python3 tools/create_design_excel.py \
  --out design/azure_landingzone_design.xlsx
```

필요 패키지:

```bash
python3 -m pip install openpyxl
```

## 2. Excel 시트

| 시트 | 용도 |
|---|---|
| `00_Control` | 설계 버전, 상태, 담당자 |
| `01_Global` | Tenant, Subscription, Region, Hub 공통값, 공통 Tag |
| `02_ResourceGroups` | Resource Group 설계 |
| `03_HubNetwork` | Hub VNet 기본 설계 |
| `04_HubSubnets` | Hub Subnet 설계 |
| `05_Workloads` | 업무/환경별 Spoke 설계 |
| `06_WorkloadSubnets` | Spoke Subnet 설계 |
| `07_VMs` | VM 설계 |
| `08_VMDisks` | VM Data Disk 설계 |
| `99_GenerationMap` | Terraform Root 출력 경로 매핑 |

각 `*_id` 값은 Excel 내부의 영구 식별자입니다. Azure 리소스 이름을 변경하더라도 ID는 가능한 한 유지합니다.

## 3. 검토용 JSON 생성

PowerShell:

```powershell
$env:TENANT_ID       = "<TENANT_ID>"
$env:SUBSCRIPTION_ID = "<SUBSCRIPTION_ID>"
$env:SSH_PUBLIC_KEY  = Get-Content "$HOME\.ssh\id_rsa.pub" -Raw

python .\tools\excel_design_to_auto_tfvars.py `
  --excel .\design\azure_landingzone_design.xlsx `
  --out .\generated_tfvars `
  --clean
```

Linux:

```bash
export TENANT_ID="<TENANT_ID>"
export SUBSCRIPTION_ID="<SUBSCRIPTION_ID>"
export SSH_PUBLIC_KEY="$(cat ~/.ssh/id_rsa.pub)"

python3 tools/excel_design_to_auto_tfvars.py \
  --excel design/azure_landingzone_design.xlsx \
  --out generated_tfvars \
  --clean
```

기본 템플릿은 다음 파일을 생성합니다.

```text
generated_tfvars/00-foundation/resource-groups/10-design.auto.tfvars.json
generated_tfvars/10-platform/hub-network/10-design.auto.tfvars.json
generated_tfvars/20-workload/sales-dev-spoke/10-design.auto.tfvars.json
generated_tfvars/30-services/vm-sales-dev/10-design.auto.tfvars.json
```

## 4. 생성 결과 미리보기

```powershell
python .\tools\publish_design_tfvars.py `
  --source .\generated_tfvars `
  --destination .\live
```

이 명령은 기본적으로 복사하지 않고 `NEW`, `CHANGED`, `UNCHANGED`만 표시합니다.

## 5. live 반영

검토가 끝난 뒤에만 `--apply`를 사용합니다.

```powershell
python .\tools\publish_design_tfvars.py `
  --source .\generated_tfvars `
  --destination .\live `
  --apply
```

## 6. Terraform 검증

각 변경 Root에서 검증합니다.

```powershell
terraform -chdir=live/00-foundation/resource-groups fmt -check
terraform -chdir=live/00-foundation/resource-groups init -backend=false
terraform -chdir=live/00-foundation/resource-groups validate

terraform -chdir=live/10-platform/hub-network init -backend=false
terraform -chdir=live/10-platform/hub-network validate

terraform -chdir=live/20-workload/sales-dev-spoke init -backend=false
terraform -chdir=live/20-workload/sales-dev-spoke validate

terraform -chdir=live/30-services/vm-sales-dev init -backend=false
terraform -chdir=live/30-services/vm-sales-dev validate
```

실제 backend와 Azure 인증을 적용한 뒤에는 기존 실행 도구로 plan을 확인합니다.

```bash
tools/tf_root.sh live/00-foundation/resource-groups plan
tools/tf_root.sh live/10-platform/hub-network plan
tools/tf_root.sh live/20-workload/sales-dev-spoke plan
tools/tf_root.sh live/30-services/vm-sales-dev plan
```

삭제 대상이 보이면 Excel 행 삭제 또는 ID 변경이 의도한 것인지 먼저 확인합니다.

## 7. 신규 업무 추가

예를 들어 `inventory-preprod`를 추가할 경우:

1. `02_ResourceGroups`에 업무 RG 추가
2. `05_Workloads`에 `inventory-preprod` 추가
3. `06_WorkloadSubnets`에 Subnet 추가
4. `07_VMs`, `08_VMDisks`에 VM과 Disk 추가
5. `99_GenerationMap`에 다음 출력 Root 추가

```text
20-workload/inventory-preprod-spoke
30-services/vm-inventory-preprod
```

그 후 변환기를 다시 실행하면 새 Root의 `10-design.auto.tfvars.json`이 생성됩니다.

## 8. 현재 지원 범위

초기 전환 버전은 다음 Module Type을 지원합니다.

```text
resource_groups
hub_network
workload_spoke
vm
```

이후 AKS, AI, Load Balancer, Private DNS, Private Endpoint, Firewall Rule을 같은 `99_GenerationMap` 방식으로 확장합니다.

## 9. 안전 원칙

- Excel은 설계 원본이며 생성된 JSON을 직접 수정하지 않습니다.
- 실제 Excel과 생성 JSON은 공개 Git에 커밋하지 않습니다.
- `generated_tfvars`에서 먼저 검토하고 `live`에 반영합니다.
- `terraform validate`와 `terraform plan` 없이 apply하지 않습니다.
- Excel의 ID 또는 행 삭제는 Terraform destroy로 이어질 수 있으므로 plan의 삭제 항목을 승인 전에 반드시 확인합니다.
