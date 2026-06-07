# Global Design과 Workload Design 분리 원칙

시스템이 하나 추가될 때마다 전역 Landing Zone Excel을 수정하지 않는다. 전역 설계서는 표준과 공통 기반만 관리하고, 업무 시스템은 `design/workloads/<system-env>/` 하위의 업무별 Excel로 관리한다.

## 전역 설계서

위치:

```text
azure_landingzone_terraform_module_design.xlsx
```

관리 대상:

```text
Management Group
Subscription 기준
Region 표준
Naming / Tag 표준
IP 대역 할당 기준
Hub Network
ExpressRoute / VPN
Private DNS Zone
Azure Policy
공통 RBAC / PIM
Terraform Backend
운영 공통 모니터링 / 보안 기준
```

전역 설계서는 신규 업무 시스템이 생길 때마다 수정하지 않는다. 신규 Subscription, 전역 IP 대역, Hub/DNS/Policy 변경처럼 공통 기반이 바뀔 때만 수정한다.

## 업무별 설계서

위치 예시:

```text
design/workloads/inventory-preprod/inventory-preprod_design.xlsx
```

관리 대상:

```text
업무명 / 환경 / 요청번호
업무 Resource Group
업무 VNet / Subnet
Web / AP / DB VM
Application Gateway / Load Balancer
업무 NSG / Port
업무 DNS / Private Endpoint
업무 Ansible 배포 변수
업무별 Terraform root
```

## Terraform State 분리

전역 State:

```text
foundation/resource-groups.tfstate
platform/hub-network.tfstate
access/private-dns-zones.tfstate
```

업무별 State:

```text
workload/inventory-preprod-spoke.tfstate
services/inventory-preprod-stack.tfstate
```

## 운영 흐름

```text
1. 전역 설계서에서 기준 확인
2. 업무별 설계서 생성 또는 수정
3. 업무별 live root 생성
4. terraform plan
5. 승인 후 terraform apply
6. Ansible 구성 배포
7. CMDB / Inventory 반영
```

이 구조를 사용하면 신규 업무 시스템 추가가 전역 Landing Zone 변경으로 보이지 않고, 업무 단위로 작게 승인하고 배포할 수 있다.
