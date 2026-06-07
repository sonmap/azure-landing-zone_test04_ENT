# 구현 가이드

## 1. 모듈별 독립 Apply 원칙

각 `live/*` 디렉터리는 하나의 독립 Terraform Root Module입니다. 각 디렉터리는 별도 Backend Key를 가져야 합니다.

예:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstatexxxxx"
    container_name       = "tfstate"
    key                  = "30-services/webwas-sales-dev.tfstate"
  }
}
```

## 2. Landing Zone 이후 자원 추가 방식

1. ITSM/CSR 요청 접수
2. 요청 유형에 따라 모듈 선택
3. Excel 또는 ITSM 입력값을 `terraform.auto.tfvars.json`으로 변환
4. 해당 `live/*` 디렉터리에서 `terraform plan`
5. 승인 후 `terraform apply`
6. 필요한 경우 Ansible 실행
7. CMDB/Inventory 반영

## 3. 모듈 매핑

| 업무 요청 | Terraform Root | Module |
|---|---|---|
| Resource Group 생성 | `00-foundation/resource-groups` | `modules/resource_group` |
| Hub Network 생성 | `10-platform/hub-network` | `modules/network_hub` |
| 부서 Spoke 생성 | `20-workload/*-spoke` | `modules/workload_spoke` |
| 단일 VM 생성 | `30-services/vm-*` | `modules/linux_vm` |
| Web/WAS Stack 생성 | `30-services/webwas-*` | `modules/web_was_stack` |
| Private AKS 생성 | `30-services/aks-*` | `modules/aks_private` |
| AI Private 환경 생성 | `30-services/ai-*` | `modules/ai_private` |
| Private Endpoint 생성 | `40-access/private-endpoint` | `modules/private_endpoint` |
| DNS Record 생성 | `40-access/dns-record` | `modules/dns_record` |
| Firewall Rule 생성 | `40-access/firewall-rule` | `modules/firewall_rule` |

## 4. Terraform과 Ansible 역할 분리

- Terraform: Azure Resource 생성과 네트워크 연결
- Ansible: VM OS 설정, Java/Tomcat/WAS, Agent, App 배포

## 5. 운영 시 보강해야 할 항목

- Azure Policy Assignment 모듈
- Diagnostic Settings / Log Analytics 모듈
- Backup Policy 연결 모듈
- Defender for Cloud 정책
- Key Vault Secret 조회 기반 Ansible 배포
- ServiceNow/ITSM API 연동
- Azure Resource Graph 기반 CMDB 검증
