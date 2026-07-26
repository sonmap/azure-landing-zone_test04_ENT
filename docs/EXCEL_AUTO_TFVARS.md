# Excel 설계 기반 `10-design.auto.tfvars.json` 생성

## 원칙

- Excel은 설계 원본(Source of Truth)입니다.
- `10-design.auto.tfvars.json`은 자동 생성 파일이며 직접 수정하지 않습니다.
- 먼저 `generated_tfvars/`에 생성하고 검증한 후 `live/`에 반영합니다.
- Terraform의 `variables.tf`가 입력 계약이며, Excel 변환기는 그 구조에 맞는 JSON을 생성합니다.

## 1. Excel 설계서 생성

Windows PowerShell:

```powershell
python .\tools\create_excel_design_template.py `
  --output .\design\azure_landingzone_design.xlsx
```

Linux:

```bash
python3 tools/create_excel_design_template.py \
  --output design/azure_landingzone_design.xlsx
```

생성되는 주요 시트:

- `01_Global`
- `02_ResourceGroups`
- `03_HubNetwork`
- `04_HubSubnets`
- `05_Workloads`
- `06_WorkloadSubnets`
- `07_VMs`
- `08_VMDisks`
- `09_AKSClusters`
- `10_AKSNodePools`
- `11_AIServices`
- `12_PrivateDNSZones`
- `99_GenerationMap`

## 2. 환경변수 설정

PowerShell:

```powershell
$env:TENANT_ID = "<TENANT_ID>"
$env:SUBSCRIPTION_ID = "<SUBSCRIPTION_ID>"
$env:SSH_PUBLIC_KEY = Get-Content "$HOME\.ssh\id_rsa.pub" -Raw
$env:AKS_LOG_ANALYTICS_WORKSPACE_ID = "<LOG_ANALYTICS_WORKSPACE_RESOURCE_ID>"
```

Linux:

```bash
export TENANT_ID="<TENANT_ID>"
export SUBSCRIPTION_ID="<SUBSCRIPTION_ID>"
export SSH_PUBLIC_KEY="$(cat ~/.ssh/id_rsa.pub)"
export AKS_LOG_ANALYTICS_WORKSPACE_ID="<LOG_ANALYTICS_WORKSPACE_RESOURCE_ID>"
```

Excel에서 `${ENV:TENANT_ID}`처럼 입력하면 변환 시 환경변수 값으로 치환됩니다.

## 3. 검토용 JSON 생성

PowerShell:

```powershell
.\tools\generate_design_tfvars.ps1
```

Linux:

```bash
tools/generate_design_tfvars.sh
```

기본 출력 예:

```text
generated_tfvars/
├── 00-foundation/resource-groups/10-design.auto.tfvars.json
├── 10-platform/hub-network/10-design.auto.tfvars.json
├── 20-workload/sales-dev-spoke/10-design.auto.tfvars.json
├── 30-services/vm-sales-dev/10-design.auto.tfvars.json
├── 30-services/aks-sales-dev/10-design.auto.tfvars.json
└── 40-access/private-dns-zones/10-design.auto.tfvars.json
```

## 4. 검증만 수행

```powershell
python .\tools\excel_design_to_auto_tfvars.py `
  --excel .\design\azure_landingzone_design.xlsx `
  --validate-only
```

검증 항목:

- 필수 ID 및 중복 ID
- Resource Group, Workload, Subnet, VM 참조 관계
- Hub/Spoke CIDR 중복
- Subnet이 VNet CIDR 내부인지 여부
- VM 사설 IP가 Subnet 안에 있는지 여부
- 중복 사설 IP와 VM별 중복 LUN
- `99_GenerationMap`의 중복·비정상 출력 경로

## 5. `live/`에 반영

검토 후 PowerShell:

```powershell
.\tools\generate_design_tfvars.ps1 -PublishLive
```

Linux:

```bash
PUBLISH_LIVE=true tools/generate_design_tfvars.sh
```

`99_GenerationMap`의 `output_root`는 `live/` 아래 상대 경로입니다. 예:

```text
00-foundation/resource-groups
10-platform/hub-network
20-workload/sales-dev-spoke
30-services/vm-sales-dev
```

## 6. Terraform 검증

```powershell
terraform -chdir=live/00-foundation/resource-groups init -backend=false
terraform -chdir=live/00-foundation/resource-groups validate
terraform -chdir=live/00-foundation/resource-groups plan
```

각 Root의 `10-design.auto.tfvars.json`은 Terraform이 자동으로 읽습니다.

## 운영 주의사항

- Excel 행 삭제는 Terraform 자원 삭제 계획으로 이어질 수 있습니다.
- `terraform plan`에 destroy가 있으면 승인 전 apply하지 않습니다.
- 실제 Excel 파일과 생성 JSON에는 내부 IP와 식별자가 포함될 수 있으므로 Git에 커밋하지 않습니다.
- 공개 가능한 구조는 `create_excel_design_template.py`에서 관리합니다.
- 하나의 VM Root에는 동일한 OS 계열과 동일한 `admin_username`을 사용합니다. 다른 OS는 별도 Root로 분리합니다.
