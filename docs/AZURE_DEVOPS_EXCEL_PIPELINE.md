# Azure DevOps Excel 설계 파이프라인

이 문서는 `pipelines/azure-pipelines-excel-design.yml`을 Azure DevOps Services에서 실행하기 위한 설정과 운영 절차를 설명합니다.

파이프라인은 Azure DevOps Secure Files의 Excel 설계서를 내려받아 Terraform root별 `10-design.auto.tfvars.json`을 만들고, 검증, Terraform Backend Bootstrap, Plan, 승인 기반 Apply를 수행합니다.

## 핵심 설계

Terraform Backend는 `live/00-foundation/resource-groups`에서 생성하지 않습니다.

`00-foundation` 자체도 `terraform init`을 수행하기 전에 State Backend가 필요하므로, 같은 Terraform root에서 Backend를 생성하면 순환 의존성이 생깁니다. 따라서 Pipeline의 `Backend` Stage가 Azure CLI로 다음 리소스를 먼저 생성하거나 검증합니다.

```text
Terraform State Resource Group
Terraform State Storage Account
Private Blob Container
Storage Blob Data Contributor 역할
```

Backend Bootstrap은 `tools/bootstrap_terraform_backend.sh`가 담당하며, 이미 존재하는 리소스는 다시 만들지 않습니다.

## 전체 처리 흐름

```text
Azure DevOps Secure Files
  azure_landingzone_design.xlsx
          |
          v
Generate Stage
  Excel 검증
  Root별 10-design.auto.tfvars.json 생성
  generated-tfvars Artifact 게시
          |
          v
Validate Stage
  생성 JSON을 임시로 live Root에 복사
  terraform fmt -check
  terraform init -backend=false
  terraform validate
          |
          v
Backend Stage
  Azure Service Connection 인증
  Backend Resource Group 생성 또는 확인
  Storage Account 생성 또는 확인
  Blob Container 생성 또는 확인
  Service Connection에 Blob Data 권한 부여 또는 확인
          |
          v
Plan Stage
  Root별 Remote Backend init
  Terraform Plan 생성
  삭제/교체 작업 검사
  terraform-plans Artifact 게시
          |
          v
Apply Stage
  main 브랜치만 허용
  Azure DevOps Environment 승인
  저장된 Plan 파일 Apply
```

`runTerraformPlan=false`와 `runTerraformApply=false`로 실행하면 `Generate`, `Validate`만 수행하고 Azure Backend에는 접근하지 않습니다.

## 1. Self-hosted Agent 준비

기본 Agent Pool:

```text
son-linux-pool
```

Agent 서버에 다음 도구가 설치되어 있어야 합니다.

```bash
python3 --version
python3 -m venv --help
terraform version
az version
git --version
bash --version
```

Rocky Linux 예:

```bash
sudo dnf install -y python3 python3-pip git
```

Terraform과 Azure CLI도 Agent에 미리 설치합니다. Plan과 Apply 사이에 Terraform 버전이 달라지면 Apply를 중지합니다.

## 2. Excel 설계서 준비

로컬에서 최초 Excel 파일을 생성합니다.

```powershell
python .\tools\create_design_excel.py `
  --out .\design\azure_landingzone_design.xlsx
```

Excel에서 Resource Group, Hub, Spoke, Subnet, VM, Disk, Generation Map을 설계한 후 저장합니다.

생성되는 `10-design.auto.tfvars.json`은 직접 수정하지 않습니다.

## 3. Secure File 등록

Azure DevOps:

```text
Pipelines
  > Library
  > Secure files
  > + Secure file
```

업로드 파일:

```text
azure_landingzone_design.xlsx
```

업로드 후 `Pipeline permissions`에서 현재 Pipeline 사용을 허용합니다.

## 4. Variable Group 생성

Azure DevOps:

```text
Pipelines
  > Library
  > Variable groups
  > + Variable group
```

Variable Group 이름:

```text
azlz-excel-design
```

등록 변수:

| 변수 | 예시 | 설명 |
|---|---|---|
| `TENANT_ID` | Entra Tenant GUID | Excel Placeholder와 Terraform Provider용 |
| `SUBSCRIPTION_ID` | Azure Subscription GUID | 배포 및 Backend 대상 Subscription |
| `SSH_PUBLIC_KEY` | `ssh-ed25519 AAAA...` | Linux VM 공개키 |
| `AZURE_SERVICE_CONNECTION` | `sc-azure-land03-platform` | Azure RM Service Connection 이름 |
| `TFSTATE_RESOURCE_GROUP` | `rg-azlz-tfstate-krc` | 생성하거나 사용할 Backend RG 이름 |
| `TFSTATE_STORAGE_ACCOUNT` | `stazlztfstate001` | 생성하거나 사용할 전역 고유 Storage Account 이름 |
| `TFSTATE_CONTAINER` | `tfstate` | 생성하거나 사용할 Private Blob Container 이름 |

중요:

- `TFSTATE_RESOURCE_GROUP`, `TFSTATE_STORAGE_ACCOUNT`, `TFSTATE_CONTAINER`은 **이미 존재하는 리소스 조회값이 아니라 생성할 이름**으로 먼저 등록할 수 있습니다.
- Pipeline의 `Backend` Stage가 값에 해당하는 리소스를 생성하거나 기존 리소스를 검증합니다.
- Storage Account 이름은 Azure 전체에서 고유해야 하며, 소문자와 숫자 3~24자로 입력합니다.
- `SSH_PUBLIC_KEY`는 공개키입니다. Private Key는 등록하지 않습니다.
- Variable Group의 `Pipeline permissions`에서 현재 Pipeline을 승인합니다.

## 5. Azure Service Connection 생성

Azure DevOps:

```text
Project settings
  > Service connections
  > New service connection
  > Azure Resource Manager
```

가능하면 Workload Identity Federation 방식을 사용합니다.

예시 이름:

```text
sc-azure-land03-platform
```

이 이름을 `AZURE_SERVICE_CONNECTION`에 등록합니다.

### Backend 자동 생성에 필요한 권한

Backend Resource Group과 Storage Account를 생성하려면 Service Connection에 대상 Subscription 또는 Resource Group의 `Contributor` 이상 권한이 필요합니다.

`Storage Blob Data Contributor` 역할을 Pipeline이 자동으로 부여하려면 추가로 다음 중 하나가 필요합니다.

```text
Owner
User Access Administrator
Role Based Access Control Administrator
```

개인 학습 Subscription에서는 최초 Bootstrap 동안 Owner를 사용할 수 있습니다. 운영 환경에서는 별도 Bootstrap Identity를 사용하거나 보안 담당자가 Role Assignment를 사전에 수행하는 방식을 권장합니다.

자동 Role Assignment를 사용하지 않을 경우 Pipeline 실행 파라미터:

```text
grantBackendRole = false
```

로 실행하고, Service Connection Identity에 `Storage Blob Data Contributor`를 사전 부여해야 합니다.

## 6. Apply 승인 Environment 생성

Azure DevOps:

```text
Pipelines
  > Environments
  > New environment
```

Environment 이름:

```text
azlz-terraform-apply
```

승인 설정:

```text
azlz-terraform-apply
  > Approvals and checks
  > Approvals
```

## 7. Pipeline 생성

Azure DevOps:

```text
Pipelines
  > New pipeline
  > GitHub
  > sonmap/azure-landing-zone_test04_ENT
  > Existing Azure Pipelines YAML file
```

YAML 경로:

```text
/pipelines/azure-pipelines-excel-design.yml
```

## 8. 실행 파라미터

| 파라미터 | 기본값 | 설명 |
|---|---|---|
| `excelSecureFile` | `azure_landingzone_design.xlsx` | Secure Files의 Excel 파일명 |
| `selectedRoot` | `all` | Plan/Apply 대상 Root |
| `runTerraformPlan` | `true` | Terraform Plan 수행 |
| `runTerraformApply` | `false` | 승인 후 Apply 수행 |
| `allowDestroy` | `false` | Delete/Replace 작업 허용 |
| `bootstrapTerraformBackend` | `true` | 누락된 Backend 리소스 자동 생성 |
| `grantBackendRole` | `true` | Service Connection에 Blob Data 역할 자동 부여 |
| `backendLocation` | `koreacentral` | Backend RG와 Storage Account 지역 |
| `applyEnvironment` | `azlz-terraform-apply` | Apply 승인 Environment |

## 9. 검증만 실행

Azure 리소스를 만들지 않고 Excel과 Terraform 구조만 검사합니다.

```text
runTerraformPlan          = false
runTerraformApply         = false
selectedRoot              = all
```

수행 Stage:

```text
Generate
Validate
```

## 10. 최초 Backend Bootstrap 확인

Plan을 실행하면 `Backend` Stage가 다음 순서로 동작합니다.

```text
1. Variable Group 값 검증
2. Subscription 선택
3. Backend Resource Group 생성 또는 확인
4. Storage Account 생성 또는 확인
5. Private Blob Container 생성 또는 확인
6. Storage Blob Data Contributor 역할 확인 또는 생성
7. Microsoft Entra 기반 Blob 접근 검증
```

Backend가 이미 존재해도 같은 설정으로 재실행할 수 있습니다.

리소스 자동 생성을 금지하고 존재 여부만 검증할 경우:

```text
bootstrapTerraformBackend = false
```

## 11. 최초 Landing Zone 구축 순서

최초 구축에서는 `selectedRoot=all`로 한 번에 Apply하지 않습니다.

Plan Stage는 모든 Root를 먼저 Plan하므로, 뒤쪽 Root가 아직 Apply되지 않은 앞쪽 리소스를 조회하면 실패할 수 있습니다.

### 1차: Foundation

```text
selectedRoot      = 00-foundation/resource-groups
runTerraformPlan  = true
runTerraformApply = true
```

생성 대상:

```text
Landing Zone Resource Groups
```

Terraform Backend는 이 Root가 아니라 앞선 `Backend` Stage에서 생성됩니다.

### 2차: Hub Platform

```text
selectedRoot      = 10-platform/hub-network
runTerraformPlan  = true
runTerraformApply = true
```

### 3차: Workload Spoke

```text
selectedRoot      = 20-workload/sales-dev-spoke
runTerraformPlan  = true
runTerraformApply = true
```

### 4차: VM Service

```text
selectedRoot      = 30-services/vm-sales-dev
runTerraformPlan  = true
runTerraformApply = true
```

## 12. State Key 구조

각 Root는 같은 Storage Account와 Container를 사용하되 별도 State Key를 사용합니다.

```text
00-foundation/resource-groups.tfstate
10-platform/hub-network.tfstate
20-workload/sales-dev-spoke.tfstate
30-services/vm-sales-dev.tfstate
```

## 13. 주요 오류 해결

### Variable Group 오류

```text
Variable group was not found or is not authorized for use
```

확인:

```text
Pipelines > Library > azlz-excel-design
Pipeline permissions > 현재 Pipeline 승인
```

### Secure File 오류

```text
secure file could not be found or is not authorized
```

확인:

```text
Pipelines > Library > Secure files
azure_landingzone_design.xlsx
Pipeline permissions > 현재 Pipeline 승인
```

### Role Assignment 오류

```text
The client does not have authorization to perform roleAssignments/write
```

원인:

```text
Service Connection에 Role Assignment 생성 권한이 없음
```

해결:

```text
Service Connection에 Owner/User Access Administrator/RBAC Administrator 부여
```

또는:

```text
grantBackendRole=false
```

로 실행하고 역할을 사전 등록합니다.

### Storage Account 이름 오류

```text
StorageAccountAlreadyTaken
```

`TFSTATE_STORAGE_ACCOUNT`를 다른 전역 고유 이름으로 변경합니다.

### Backend Blob 접근 오류

```text
AuthorizationPermissionMismatch
```

Service Connection Identity에 Storage Account Scope의 다음 역할을 확인합니다.

```text
Storage Blob Data Contributor
```

## 관련 파일

```text
pipelines/azure-pipelines-excel-design.yml
tools/bootstrap_terraform_backend.sh
tools/excel_design_to_auto_tfvars.py
tools/create_design_excel.py
```
