# 00 Foundation - Resource Groups

이 Terraform root는 Landing Zone에서 사용하는 기본 Resource Group만 생성합니다.

## 생성 대상

```text
Azure Resource Groups
```

실제 생성 코드는 `modules/resource_group`을 호출하며 Storage Account 또는 Blob Container는 생성하지 않습니다.

## Terraform Backend를 여기서 만들지 않는 이유

이 root도 실행 전에 다음 명령이 필요합니다.

```text
terraform init
```

Remote State를 사용하는 `terraform init`에는 이미 존재하는 Backend Resource Group, Storage Account, Container가 필요합니다. 따라서 이 root 안에서 Backend를 동시에 만들면 다음과 같은 순환 의존성이 발생합니다.

```text
00-foundation 실행에 Backend 필요
        ↕
00-foundation으로 Backend 생성 시도
```

Azure DevOps Pipeline에서는 `Backend` Stage가 `tools/bootstrap_terraform_backend.sh`를 실행하여 Terraform Plan 전에 Backend를 생성하거나 검증합니다.

## 최초 구축 순서

```text
1. Generate
2. Validate
3. Backend Bootstrap
4. 00-foundation/resource-groups Plan
5. 승인 후 Apply
6. 10-platform/hub-network
7. 20-workload/sales-dev-spoke
8. 30-services/vm-sales-dev
```

Pipeline 실행 파라미터:

```text
selectedRoot      = 00-foundation/resource-groups
runTerraformPlan  = true
runTerraformApply = true
```

Backend 이름은 Azure DevOps Variable Group `azlz-excel-design`에 다음 값으로 등록합니다.

```text
TFSTATE_RESOURCE_GROUP
TFSTATE_STORAGE_ACCOUNT
TFSTATE_CONTAINER
```

이 값들은 사전에 존재하는 리소스의 조회값이 아니라, Backend Stage가 생성할 대상 이름으로 입력할 수 있습니다.
