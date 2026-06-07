# Excel 시트와 Terraform 모듈 매핑

| Excel 시트 | Terraform 대상 |
|---|---|
| `01_모듈카탈로그` | 모듈 선택 기준 |
| `02_Foundation` | `live/00-foundation/*` |
| `03_Network_Connectivity` | `live/10-platform/*`, `live/40-access/*` |
| `04_Workload_LZ` | `live/20-workload/*` |
| `05_VM_Module` | `live/30-services/vm-*` |
| `06_Web_WAS_DB_Stack` | `live/30-services/webwas-*` |
| `07_AKS_Module` | `live/30-services/aks-*` |
| `08_AI_Private_Module` | `live/30-services/ai-*` |
| `09_Access_Network_Module` | `live/40-access/*` |
| `10_Ansible_Module` | `ansible/*` |
| `11_ITSM_CMDB` | 태그/CMDB/CSR 연계 |
| `12_Pipeline_Model` | `pipelines/*` |
| `13_TF_Var_Schema` | `variables.tf`, `terraform.tfvars.example` |
| `14_Naming_Tags` | Naming/Tag 공통 입력값 |
| `99_생성순서` | Apply 순서 및 State 분리 |

## Excel에서 `.tfvars` 생성

`tools/excel_to_tfvars.py`는 `azure_landingzone_terraform_module_design.xlsx`를 읽어서 Terraform 입력 변수 파일을 생성한다.

기본 실행:

```powershell
cd C:\개인자료\AI_Agent_son01\azure_land06
& 'C:\Users\inno\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' .\tools\excel_to_tfvars.py `
  --excel .\azure_landingzone_terraform_module_design.xlsx `
  --out generated_tfvars `
  --tenant-id <TENANT_ID> `
  --subscription-id <SUBSCRIPTION_ID>
```

`--out generated_tfvars`는 실제 배포용 `live` 디렉터리를 덮어쓰지 않는 검토용 출력이다. 검토 후 배포 루트에 직접 생성하려면 `--out live`로 실행한다.

JSON 형식이 필요하면:

```powershell
& 'C:\Users\inno\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' .\tools\excel_to_tfvars.py `
  --excel .\azure_landingzone_terraform_module_design.xlsx `
  --out generated_tfvars_json `
  --format json `
  --tenant-id <TENANT_ID> `
  --subscription-id <SUBSCRIPTION_ID>
```

지원되는 변수 치환:

| Excel 입력값 | 치환값 |
|---|---|
| `${tenant_id}` | `--tenant-id` |
| `${subscription_id}` | `--subscription-id` |
| `${location}` | `--location` |
| `${hub_resource_group_name}` | `--hub-resource-group-name` |
| `${hub_vnet_name}` | `--hub-vnet-name` |
| `${hub_vnet_id}` | 구독/RG/VNet 이름으로 생성한 Hub VNet Resource ID |
| `${hub_dns_inbound_ip}` | `--hub-dns-inbound-ip` |
| `${firewall_private_ip}` | `--firewall-private-ip` |

현재 생성 대상:

| 출력 경로 | 원본 시트 |
|---|---|
| `00-foundation/resource-groups/terraform.tfvars` | `04_Workload_LZ` |
| `10-platform/hub-network/terraform.tfvars` | CLI 기본값 및 Hub 표준값 |
| `20-workload/*-spoke/terraform.tfvars` | `04_Workload_LZ` |
| `30-services/vm-*/terraform.tfvars` | `05_VM_Module` |
| `30-services/aks-*/terraform.tfvars` | `07_AKS_Module` |
| `30-services/ai-*/terraform.tfvars` | `08_AI_Private_Module` |
| `40-access/private-dns-zones/terraform.tfvars` | Private DNS 표준값 |

주의:

- Excel에 특정 환경의 Workload LZ 행이 없으면 VM/AKS/AI는 `rg-sl-<업무>-<env>`, `vnet-sl-<업무>-<env>` 형식으로 생성한다.
- `ssh_public_key`, Log Analytics Workspace ID 같은 민감하거나 환경 의존적인 값은 실행 옵션 또는 생성 후 검토로 확정한다.
- 생성된 `.tfvars`는 바로 apply하지 말고 `terraform plan`으로 확인한다.
