# Azure Landing Zone Terraform Lab

Excel 설계서를 기준으로 Azure Landing Zone, 네트워크, 워크로드, VM, AKS, Private Endpoint, 모니터링, Ansible 연계를 단계별로 배포하는 Terraform 예제 프로젝트입니다.

이 저장소는 학습 및 사전 검증용 템플릿입니다. 실제 운영 환경에 적용하기 전에는 보안 정책, 네트워크 주소, 권한 모델, 비용 정책, 삭제 방지 정책을 조직 기준에 맞게 검토해야 합니다.

## 주요 기능

- Excel 설계값을 Terraform 변수 파일로 변환
- Foundation, Platform, Workload, Service, Access 영역 분리
- Hub-Spoke 네트워크 구조
- 내부 전용 VM, AKS, AI 서비스 구성 예제
- Application Gateway, Internal Load Balancer 구성 예제
- Private DNS, Private Endpoint, Firewall Rule 구성 예제
- Terraform 이후 Ansible 인벤토리 생성 및 서버 설정 연계
- 테스트 환경에서 1시간 후 자동 destroy 예약 구조

## 디렉터리 구조

```text
.
├── modules/                 # 재사용 Terraform 모듈
├── live/                    # 실제 배포 루트. 영역별 독립 state 사용
│   ├── 00-foundation/       # Resource Group 등 기본 자원
│   ├── 10-platform/         # Hub Network, Firewall 등 플랫폼 자원
│   ├── 20-workload/         # 부서/업무별 Spoke Landing Zone
│   ├── 30-services/         # VM, AKS, AI, LB, App Gateway 등 서비스 자원
│   └── 40-access/           # DNS, Private Endpoint, Firewall Rule
├── tools/                   # Excel 변환, Terraform 실행, destroy 예약 도구
├── ansible/                 # VM 구성관리 playbook
├── docs/                    # 설계 및 운영 가이드
├── pipelines/               # CI/CD 예제
└── backend.hcl.example      # Terraform backend 예제
```

## Git 업로드 주의사항

아래 파일은 실제 계정 정보, state, 로그, 키가 포함될 수 있으므로 Git에 올리면 안 됩니다.

```gitignore
.ssh/
.terraform/
*.tfstate
*.tfstate.*
*.tfplan
tfplan
crash.log
crash.*.log
terraform.tfvars
*.auto.tfvars
*.auto.tfvars.json
backend.hcl
generated_tfvars/
logs/
backups/
*.zip
*.tar.gz
*.xlsx
__pycache__/
*.pyc
ansible/inventories/generated/*.ini
```

공개 저장소에 올릴 때는 실제 값 대신 아래처럼 placeholder를 사용합니다.

```text
<TENANT_ID>
<SUBSCRIPTION_ID>
<RESOURCE_GROUP_NAME>
<STORAGE_ACCOUNT_NAME>
<USER_EMAIL>
<SSH_HOST>
```

## 사전 준비

Linux 서버에서 실행하는 것을 기준으로 합니다.

```bash
cd /home/son/azure_land06

terraform version
az version
python3 --version
```

Azure 로그인 상태를 확인합니다.

```bash
az account show -o table
```

필요 시 구독을 선택합니다.

```bash
az account set --subscription <SUBSCRIPTION_ID>
```

Terraform backend 예제 파일을 복사한 뒤 실제 환경값을 입력합니다.

```bash
cp backend.hcl.example backend.hcl
vi backend.hcl
```

## Excel에서 tfvars 생성

전체 Excel 설계값을 기준으로 tfvars를 생성합니다.

```bash
python3 tools/excel_to_tfvars.py \
  --excel azure_landingzone_terraform_module_design.xlsx \
  --out live \
  --tenant-id <TENANT_ID> \
  --subscription-id <SUBSCRIPTION_ID>
```

특정 대상만 갱신하려면 선택 갱신 스크립트를 사용합니다.

```bash
tools/update_selected_tfvars.sh --target azure-firewall
tools/update_selected_tfvars.sh --target sales-dev-spoke
```

## Terraform 배포 순서

각 루트는 독립 state를 사용합니다. 아래 순서대로 필요한 영역만 배포합니다.

```bash
# 1. Foundation
tools/tf_root.sh live/00-foundation/resource-groups plan
tools/tf_root.sh live/00-foundation/resource-groups apply

# 2. Platform Hub Network
tools/tf_root.sh live/10-platform/hub-network plan
tools/tf_root.sh live/10-platform/hub-network apply

# 3. Workload Spoke
tools/tf_root.sh live/20-workload/api-dev-spoke plan
tools/tf_root.sh live/20-workload/api-dev-spoke apply

# 4. Service 예시: AKS
tools/tf_root.sh live/30-services/aks-api-dev plan
tools/tf_root.sh live/30-services/aks-api-dev apply

# 5. Service 예시: VM
tools/tf_root.sh live/30-services/vm-sales-dev plan
tools/tf_root.sh live/30-services/vm-sales-dev apply
```

## 삭제 방법

개별 루트 삭제는 해당 루트에서 destroy를 수행합니다.

```bash
tools/tf_root.sh live/30-services/aks-api-dev destroy
tools/tf_root.sh live/20-workload/api-dev-spoke destroy
```

테스트 환경에서는 전체 자원을 1시간 후 자동 삭제하도록 예약할 수 있습니다.

```bash
tools/schedule_destroy_all.sh 3600
```

운영 환경에서는 실수 삭제를 막기 위해 destroy guard, 리소스 잠금, 승인 절차를 별도로 적용해야 합니다.

## 자원 확인 명령

전체 Resource Group 확인:

```bash
az group list -o table
```

전체 Azure 자원 확인:

```bash
az resource list -o table
```

특정 Resource Group 자원 확인:

```bash
az resource list -g <RESOURCE_GROUP_NAME> -o table
```

AKS 확인:

```bash
az aks list -o table
```

VM quota 확인:

```bash
az vm list-usage -l koreacentral \
  --query "[?localName=='Total Regional vCPUs'].{Name:localName,Used:currentValue,Limit:limit}" \
  -o table
```

## 운영 시 변경 절차

1. Excel 설계서에서 변경 요청 항목을 수정합니다.
2. 변경 대상만 tfvars로 변환합니다.
3. 해당 Terraform root만 plan을 수행합니다.
4. plan 결과에서 생성, 변경, 삭제 대상을 검토합니다.
5. 승인 후 apply를 수행합니다.
6. 필요 시 Terraform output으로 Ansible inventory를 생성하고 playbook을 실행합니다.
7. CMDB, 운영 문서, 비용 태그를 갱신합니다.

## 보안 원칙

- Public IP는 기본 금지합니다.
- VM, AKS, AI, Storage, Key Vault는 Private Network 접근을 우선합니다.
- 운영 계정은 최소 권한과 PIM 승인을 기준으로 합니다.
- Terraform state와 tfvars는 Git에 저장하지 않습니다.
- SSH 개인키, kubeconfig, access token, backend 설정은 저장소에 포함하지 않습니다.
- 테스트 환경은 TTL destroy를 사용하고, 운영 환경은 승인 없는 destroy를 차단합니다.

## 참고 문서

상세 설계와 운영 절차는 `docs/` 디렉터리를 참고합니다.

- `docs/IMPLEMENTATION_GUIDE.md`
- `docs/DEPLOYMENT_RUNBOOK.md`
- `docs/TFVARS_MAPPING.md`
- `docs/TERRAFORM_TTL_DESTROY.md`
- `docs/MONITORING_DESIGN.md`
- `docs/AZURE_RESOURCE_LIST.md`
