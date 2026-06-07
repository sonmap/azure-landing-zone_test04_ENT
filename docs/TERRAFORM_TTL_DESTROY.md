# Terraform 1시간 TTL 자동 삭제

이 저장소는 검증 환경 비용 방지를 위해 `tools/tf_root.sh apply` 성공 후 전체 Terraform root를 1시간 뒤 destroy하도록 예약한다.

## 기본값

```bash
TF_AUTO_DESTROY_ENABLED=true
TF_AUTO_DESTROY_AFTER_SECONDS=3600
```

`tools/tf_root.sh <root> apply`를 사용하면 apply 성공 후 자동으로 아래 스크립트가 호출된다.

```bash
tools/schedule_destroy_all.sh 3600
```

## 수동 예약

현재 생성된 모든 자원을 1시간 뒤 삭제 예약하려면:

```bash
cd /home/son/azure_land06
tools/schedule_destroy_all.sh 3600
```

30분 뒤 삭제:

```bash
tools/schedule_destroy_all.sh 1800
```

## 예약 상태 확인

```bash
cat logs/destroy-after-ttl.pid
cat logs/destroy-after-ttl.scheduled_at
ps -fp "$(cat logs/destroy-after-ttl.pid)"
tail -f logs/destroy-after-ttl.log
```

## 자동 예약 끄기

장시간 유지해야 하는 운영 리소스는 apply 전에 명시적으로 꺼야 한다.

```bash
export TF_AUTO_DESTROY_ENABLED=false
tools/tf_root.sh live/20-workload/sales-dev-spoke apply
```

## 주의

직접 `terraform apply`를 실행하면 TTL 예약을 우회한다. 운영 표준은 반드시 `tools/tf_root.sh`를 사용하는 것이다.

## 프로덕션 삭제 보호

`tools/tf_root.sh destroy`는 기본적으로 production root를 차단한다.

차단 기준:

```text
Terraform root 경로에 -prod 또는 /prod 포함
terraform.tfvars 안에 env = "prod" 또는 environment = "prod" 포함
```

TTL 자동 삭제 스크립트도 `*-prod-*` root는 건너뛴다.

정말 의도적으로 production destroy가 필요할 때만 아래처럼 명시적으로 override 한다.

```bash
ALLOW_PROD_DESTROY=true tools/tf_root.sh live/20-workload/sales-prod-spoke destroy
```

운영 환경에서는 Azure Management Lock `CanNotDelete`도 별도로 적용하는 것을 권장한다. Terraform 스크립트 보호는 실수 방지용이고, Azure Lock은 Azure API 레벨의 삭제 방지다.
