# Excel 기반 40-access 구성 가이드

이 문서는 `design/azure_landingzone_design.xlsx`에서 40-access 영역을 설계하고 Terraform root별 `10-design.auto.tfvars.json`을 생성하는 방법을 설명합니다.

## 추가된 Excel 시트

| 시트 | 용도 |
|---|---|
| `09_PrivateDNSZones` | Private DNS Zone 정의 |
| `10_PrivateDNSLinks` | Hub/Workload VNet Link 정의 |
| `11_PrivateEndpoints` | Private Endpoint와 대상 Resource ID 정의 |
| `12_FirewallRuleGroups` | Firewall Policy Rule Collection Group 정의 |
| `13_FirewallNetworkRules` | Network Rule Collection과 Rule 정의 |
| `14_FirewallApplicationRules` | Application Rule Collection과 Rule 정의 |
| `15_DNSRecords` | Private DNS A Record 정의 |
| `99_GenerationMap` | 각 설계를 Terraform root에 매핑 |

## 기본 활성화 상태

기본 Excel은 바로 테스트할 수 있는 다음 항목만 활성화합니다.

```text
40-access/private-dns-zones = Y
40-access/dns-record        = Y
```

다음 항목은 실제 대상 Resource ID 또는 Firewall Policy가 필요하므로 기본 비활성화합니다.

```text
40-access/private-endpoint = N
40-access/firewall-rule    = N
```

Private Endpoint 또는 Firewall Rule을 사용하려면 해당 설계 시트의 행과 `99_GenerationMap` 행을 모두 `Y`로 변경해야 합니다.

## 기본 예제

### Private DNS

```text
Zone: internal.sl.local
Resource Group: rg-sl-hub-krc
VNet Links:
- vnet-sl-hub-krc
- vnet-sl-sales-dev
```

### DNS A Records

```text
sales-dev-web.internal.sl.local = 10.40.1.10
sales-dev-was.internal.sl.local = 10.40.2.10
```

### VM Size

```text
WEB01 = Standard_D2s_v3
WAS01 = Standard_D4s_v3
```

## Excel 생성

저장소 root에서 실행합니다.

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip openpyxl

python tools/create_design_excel.py \
  --out design/azure_landingzone_design.xlsx \
  --force
```

기존 Excel을 직접 수정한 경우에는 `create_design_excel.py --force`를 다시 실행하지 않습니다. 이 명령은 기본 설계서로 덮어씁니다.

## tfvars 생성

```bash
export TENANT_ID="$(az account show --query tenantId -o tsv)"
export SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
export SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)"

python tools/excel_design_to_auto_tfvars.py \
  --excel design/azure_landingzone_design.xlsx \
  --out generated_tfvars \
  --tenant-id "$TENANT_ID" \
  --subscription-id "$SUBSCRIPTION_ID" \
  --ssh-public-key "$SSH_PUBLIC_KEY" \
  --clean
```

기본 설정에서는 다음 파일이 생성됩니다.

```text
generated_tfvars/00-foundation/resource-groups/10-design.auto.tfvars.json
generated_tfvars/10-platform/hub-network/10-design.auto.tfvars.json
generated_tfvars/20-workload/sales-dev-spoke/10-design.auto.tfvars.json
generated_tfvars/30-services/vm-sales-dev/10-design.auto.tfvars.json
generated_tfvars/40-access/private-dns-zones/10-design.auto.tfvars.json
generated_tfvars/40-access/dns-record/10-design.auto.tfvars.json
```

## live root에 반영

```bash
while IFS= read -r src; do
  rel="${src#generated_tfvars/}"
  dst="live/$rel"
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  echo "copied: $src -> $dst"
done < <(
  find generated_tfvars \
    -type f \
    -name '10-design.auto.tfvars.json' \
    | sort
)
```

## 최초 적용 순서

의존성이 있으므로 최초 배포는 root별로 Plan과 Apply를 나누어 실행합니다.

```text
1. 00-foundation/resource-groups
2. 10-platform/hub-network
3. 20-workload/sales-dev-spoke
4. 30-services/vm-sales-dev
5. 40-access/private-dns-zones
6. 40-access/firewall-rule       (활성화한 경우)
7. 40-access/private-endpoint    (대상 서비스 생성 후)
8. 40-access/dns-record
```

Linux 직접 실행 예:

```bash
tf_plan  live/40-access/private-dns-zones
tf_apply live/40-access/private-dns-zones

tf_plan  live/40-access/dns-record
tf_apply live/40-access/dns-record
```

## Private Endpoint 활성화

다음을 모두 수정합니다.

1. `09_PrivateDNSZones`: 대상 서비스용 Zone을 `Y`로 변경
2. `10_PrivateDNSLinks`: 필요한 VNet Link를 `Y`로 변경
3. `11_PrivateEndpoints`: 실제 `private_connection_resource_id` 입력 후 `Y`
4. `99_GenerationMap`: `gen-private-endpoint`를 `Y`

예를 들어 Storage Blob Private Endpoint는 다음 값이 필요합니다.

```text
subresource_names      = blob
private_dns_zone_ids   = pdns-blob
```

Private Endpoint 대상 Storage Account, Key Vault, Azure OpenAI 등의 리소스가 먼저 생성되어 있어야 합니다.

## Firewall Rule 활성화

다음을 모두 수정합니다.

1. `12_FirewallRuleGroups`: 실제 Firewall Policy ID 입력 후 `Y`
2. `13_FirewallNetworkRules`: 사용할 Network Rule을 `Y`
3. `14_FirewallApplicationRules`: 사용할 Application Rule을 `Y`
4. `99_GenerationMap`: `gen-firewall-rule`을 `Y`

Firewall Policy가 먼저 존재해야 합니다. 기본 예제의 Policy ID와 대상 IP/FQDN은 실제 환경값으로 변경해야 합니다.
