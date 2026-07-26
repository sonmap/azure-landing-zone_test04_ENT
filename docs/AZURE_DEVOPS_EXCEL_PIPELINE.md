# Azure DevOps Excel 설계 파이프라인

이 문서는 `pipelines/azure-pipelines-excel-design.yml`을 Azure DevOps Services에서 실행하기 위한 설정과 운영 절차를 설명합니다.

파이프라인은 실제 Excel 설계서를 Git에 저장하지 않습니다. Excel은 Azure DevOps Library의 Secure Files에서 내려받고, Variable Group과 Azure Resource Manager Service Connection을 사용하여 Terraform 입력 생성, 검증, Plan, 승인 기반 Apply를 수행합니다.

## 처리 흐름

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
Plan Stage
  Azure Service Connection 인증
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

`runTerraformApply`의 기본값은 `false`입니다. Apply를 활성화하더라도 `main` 브랜치가 아니면 Apply Stage는 실행되지 않습니다.

## 1. Self-hosted Agent 준비

기본 Agent Pool은 기존 Rocky Linux Agent Pool인 다음 값입니다.

```text
son-linux-pool
```

Agent 서버에서 다음 명령이 실행되어야 합니다.

```bash
python3 --version
python3 -m venv --help
terraform version
az version
curl --version
```

Python의 `venv` 모듈이 없다면 Rocky Linux에서 관리자 권한으로 설치합니다.

```bash
sudo dnf install -y python3 python3-pip
```

Terraform과 Azure CLI는 Agent에 미리 설치하는 것을 권장합니다. Plan과 Apply 사이에 Terraform 버전이 달라지면 파이프라인은 Apply를 중지합니다.

## 2. Excel 설계서 준비

로컬에서 최초 Excel 파일을 생성합니다.

```powershell
python .\tools\create_design_excel.py `
  --out .\design\azure_landingzone_design.xlsx
```

Excel에서 Resource Group, Hub, Spoke, Subnet, VM, Disk, Generation Map을 설계한 후 저장합니다.

생성된 JSON 파일은 직접 수정하지 않습니다.

## 3. Secure Files 등록

Azure DevOps에서 다음 순서로 이동합니다.

```text
Pipelines
  > Library
  > Secure files
  > + Secure file
```

다음 파일을 업로드합니다.

```text
azure_landingzone_design.xlsx
```

업로드 후 해당 Secure File의 Pipeline permissions에서 이 파이프라인 사용을 허용합니다.

파이프라인의 기본 파라미터 `excelSecureFile`은 위 파일명과 동일합니다. 다른 이름으로 등록했다면 파이프라인 실행 화면에서 실제 Secure File 이름을 입력합니다.

## 4. Variable Group 생성

Azure DevOps에서 다음 위치로 이동합니다.

```text
Pipelines
  > Library
  > Variable groups
  > + Variable group
```

Variable Group 이름은 다음과 같이 생성합니다.

```text
azlz-excel-design
```

다음 변수를 등록합니다.

| 변수 | 예시 | Secret 권장 | 용도 |
|---|---|---:|---|
| `TENANT_ID` | Entra Tenant GUID | Y | Terraform Provider Tenant |
| `SUBSCRIPTION_ID` | Azure Subscription GUID | Y | 배포 대상 Subscription |
| `SSH_PUBLIC_KEY` | `ssh-rsa AAAA...` | 선택 | Linux VM Public Key |
| `AZURE_SERVICE_CONNECTION` | `sc-azure-land03-platform` | N | Azure RM Service Connection 이름 |
| `TFSTATE_RESOURCE_GROUP` | `rg-sl-tfstate-krc` | N | Terraform Backend RG |
| `TFSTATE_STORAGE_ACCOUNT` | `stslztfstate18fbfa69` | N | Terraform State Storage Account |
| `TFSTATE_CONTAINER` | `tfstate` | N | Terraform State Container |

Variable Group의 Pipeline permissions에서도 이 파이프라인 사용을 허용합니다.

`SSH_PUBLIC_KEY`는 공개키이므로 일반 변수로 둘 수 있습니다. Private Key, Password, Client Secret은 Excel이나 Variable Group의 일반 변수에 저장하지 않습니다.

## 5. Azure Service Connection 생성

Azure DevOps에서 다음 위치로 이동합니다.

```text
Project settings
  > Service connections
  > New service connection
  > Azure Resource Manager
```

가능하면 Workload Identity Federation 방식을 사용합니다.

예시 Service Connection 이름:

```text
sc-azure-land03-platform
```

이 이름을 Variable Group의 `AZURE_SERVICE_CONNECTION` 값으로 등록합니다.

Service Connection의 서비스 주체 또는 Managed Identity에는 최소한 다음 권한이 필요합니다.

- 배포 대상 Scope에 필요한 Terraform Resource 권한
- Terraform State Storage Account에 `Storage Blob Data Contributor`

파이프라인 전체에 Subscription Owner를 부여하는 방식은 권장하지 않습니다.

## 6. Apply 승인 Environment 생성

Azure DevOps에서 다음 위치로 이동합니다.

```text
Pipelines
  > Environments
  > New environment
```

Environment 이름:

```text
azlz-terraform-apply
```

Environment를 만든 후 다음 메뉴에서 승인자를 지정합니다.

```text
azlz-terraform-apply
  > Approvals and checks
  > Approvals
```

승인 설정은 YAML 파일 내부가 아니라 Azure DevOps Environment에서 관리합니다.

## 7. Pipeline 생성

Azure DevOps에서 다음 순서로 생성합니다.

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

저장 후 Run pipeline을 선택합니다.

## 8. 실행 파라미터

| 파라미터 | 기본값 | 설명 |
|---|---|---|
| `agentPool` | `son-linux-pool` | Self-hosted Agent Pool |
| `excelSecureFile` | `azure_landingzone_design.xlsx` | Secure Files의 Excel 파일명 |
| `selectedRoot` | `all` | Plan/Apply 대상 Root |
| `runTerraformPlan` | `true` | Terraform Plan 수행 여부 |
| `runTerraformApply` | `false` | 승인 후 Apply 수행 여부 |
| `allowDestroy` | `false` | Delete/Replace 작업 허용 여부 |
| `applyEnvironment` | `azlz-terraform-apply` | Apply 승인 Environment |

## 9. 검증만 실행

Excel 구조와 Terraform 변수 구조만 검사할 경우:

```text
runTerraformPlan  = false
runTerraformApply = false
selectedRoot      = all
```

수행 단계:

```text
Generate
Validate
```

Azure 인증과 Terraform Backend 접근은 사용하지 않습니다.

## 10. Plan 실행

전체 기존 환경의 변경 Plan을 확인할 경우:

```text
runTerraformPlan  = true
runTerraformApply = false
selectedRoot      = all
allowDestroy      = false
```

Plan Artifact에는 다음 내용이 포함됩니다.

```text
terraform-plans/
  roots.txt
  terraform-version.txt
  <root>/tfplan
  <root>/tfplan.txt
  <root>/tfplan.json
```

Terraform Plan 파일에는 민감한 값이 포함될 수 있으므로 Pipeline Artifact 접근 권한과 보존 기간을 제한해야 합니다.

## 11. 최초 구축 실행 순서

최초 구축에서는 뒤쪽 Root가 아직 생성되지 않은 VNet 또는 Subnet을 Data Source로 조회할 수 있습니다. 따라서 `selectedRoot=all`로 한 번에 Apply하지 않고 다음 순서로 Root를 하나씩 실행합니다.

### 1단계: Foundation

```text
selectedRoot      = 00-foundation/resource-groups
runTerraformPlan  = true
runTerraformApply = true
```

### 2단계: Hub Platform

```text
selectedRoot      = 10-platform/hub-network
runTerraformPlan  = true
runTerraformApply = true
```

### 3단계: Workload Spoke

```text
selectedRoot      = 20-workload/sales-dev-spoke
runTerraformPlan  = true
runTerraformApply = true
```

### 4단계: VM Service

```text
selectedRoot      = 30-services/vm-sales-dev
runTerraformPlan  = true
runTerraformApply = true
```

각 실행에서 Plan을 검토한 뒤 `azlz-terraform-apply` Environment 승인을 수행합니다.

## 12. 기존 환경 전체 변경

이미 Foundation, Hub, Spoke가 생성된 환경에서는 다음 값으로 전체 Plan을 확인할 수 있습니다.

```text
selectedRoot      = all
runTerraformPlan  = true
runTerraformApply = false
```

전체 Plan 검토 후에도 운영 Apply는 Root별로 분리하는 것을 권장합니다. Root별 State와 장애 영향 범위를 분리할 수 있기 때문입니다.

## 13. 삭제 및 교체 보호

기본값은 다음과 같습니다.

```text
allowDestroy = false
```

Terraform Plan의 Resource Change Action에 `delete`가 포함되면 파이프라인이 실패합니다. 다음 작업도 차단 대상입니다.

```text
Delete
Delete + Create 형태의 Resource Replacement
```

Excel 행 삭제, ID 변경, Resource Name 변경이 의도된 작업인지 확인한 후에만 다음 값을 사용합니다.

```text
allowDestroy = true
```

`allowDestroy=true`는 삭제를 자동 승인하는 기능이 아닙니다. Plan 생성을 허용하는 기능이며, 실제 Apply는 별도의 Environment 승인이 필요합니다.

## 14. GitHub 브랜치 정책

Apply Stage는 다음 조건을 모두 만족해야 실행됩니다.

```text
runTerraformApply = true
Build.SourceBranch = refs/heads/main
앞 단계 성공
Environment 승인 완료
```

Feature Branch와 Pull Request Branch에서는 Generate, Validate, Plan까지만 사용합니다.

## 15. Azure DevOps Server 사용 시

이 YAML은 Azure DevOps Services의 Pipeline Artifact를 사용합니다.

Azure DevOps Server에서 `PublishPipelineArtifact@1`을 지원하지 않는 버전을 사용한다면 다음 Task로 변경해야 합니다.

```text
PublishBuildArtifacts@1
DownloadBuildArtifacts@1
```

Secure Files, Service Connection, Environment Approval 지원 여부도 사용하는 Azure DevOps Server 버전에 맞춰 확인해야 합니다.

## 16. 운영 권장사항

- Excel 변경 이력은 SharePoint, OneDrive 또는 승인된 문서 저장소에서 관리합니다.
- Secure Files에는 승인된 최신 Excel만 업로드합니다.
- Excel 업로드 담당자와 Terraform Apply 승인자를 분리합니다.
- Variable Group, Secure File, Service Connection은 필요한 Pipeline에만 권한을 부여합니다.
- Terraform State Storage는 Public Network를 제한하고 Azure AD 인증을 사용합니다.
- `allowDestroy=true` 실행은 변경 요청 번호와 승인 근거를 남깁니다.
- 운영 Apply는 Root 하나씩 실행합니다.
