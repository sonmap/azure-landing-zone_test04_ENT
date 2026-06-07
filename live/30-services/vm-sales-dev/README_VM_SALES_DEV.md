# vm-sales-dev

Sales DEV 환경의 VM 서버를 역할별 tfvars 파일로 관리하는 Terraform Root Module입니다.

## 실행

```bash
cd live/30-services/vm-sales-dev
terraform init -reconfigure
terraform fmt
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

## 파일 구조

- `00-common.auto.tfvars`: 공통 RG, Region, SSH Key, Tag
- `10-network.auto.tfvars`: VNet 정보
- `20-image.auto.tfvars`: OS Image 정보
- `30-web.auto.tfvars`: WEB VM 목록
- `31-was.auto.tfvars`: WAS VM 목록
- `32-db.auto.tfvars`: DB VM 목록
- `33-agent.auto.tfvars`: DevOps Agent VM 목록

## 주의

이미 단일 VM 방식으로 `vm-sl-sales-dev-was01`을 생성한 상태에서 이 구조로 전환하면 Terraform resource address가 바뀝니다.
기존 VM 재생성을 막으려면 `terraform state mv`가 필요할 수 있습니다.
