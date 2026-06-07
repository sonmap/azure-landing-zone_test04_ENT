# 추가 반영된 Landing Zone 기능

다음 항목은 운영형 Azure Landing Zone에서 ALB/NLB 외에 추가로 필요한 설계 영역이다. Excel 설계서에 시트로 반영했고, `19_TFVars_Mapping`에도 `tfvars path`와 선택 갱신 명령을 추가했다.

| 기능 | Excel 시트 | 주요 목적 |
|---|---|---|
| KMS / Key Vault | `21_KMS_KeyVault` | CMK, secret, key rotation, private endpoint |
| IAM / RBAC / PIM | `22_IAM_RBAC_PIM` | 부서별 권한, PIM, 승인자, MFA/CA |
| Managed Identity | `23_ManagedIdentity` | VM/AKS/Container Apps 관리 ID |
| Backup / DR | `24_Backup_DR` | VM/Storage 백업, RPO/RTO, DR Region |
| Monitoring / Alert | `25_Monitoring_Alert` | Log Analytics, Diagnostic, Alert, Sentinel |
| WAF / DDoS | `26_WAF_DDoS` | Application Gateway WAF, DDoS Plan |
| Private Endpoint Request | `27_PrivateEndpoint_Request` | PaaS 사설 연결 요청 표준화 |
| Compliance / Policy | `28_Compliance_Policy` | Public IP 차단, Private Endpoint 감사 |
| Operations Runbook | `29_Operations_Runbook` | 운영 절차, rollback, 1시간 검증 후 삭제 |
| Container Apps | `30_ContainerApps` | GCP Cloud Run 대응 서비스 |

## 운영 흐름

1. Excel에서 필요한 시트에 요청 행을 추가하거나 수정한다.
2. `19_TFVars_Mapping`에서 해당 행의 `tfvars path`와 선택 갱신 명령을 확인한다.
3. `tools/update_selected_tfvars.sh` 또는 확장 대상은 `tools/update_extended_tfvars.sh` 형태의 명령으로 해당 영역만 갱신한다.
4. 출력된 Terraform root에서 `terraform plan`을 확인한다.
5. 승인된 변경만 `terraform apply` 한다.

## 우선순위

운영 적용 우선순위는 다음 순서를 권장한다.

1. IAM / RBAC / PIM
2. KMS / Key Vault
3. Monitoring / Diagnostic / Alert
4. Backup / DR
5. WAF / DDoS
6. Private Endpoint Request
7. Managed Identity
8. Container Apps
9. Compliance / Policy
10. Operations Runbook

## 주의

`Azure Firewall`, `Application Gateway`, `DDoS Protection Plan`, `AKS`, `Azure OpenAI`, `AI Search`는 비용 영향이 큰 리소스다. Excel에서 `Status=Approved`와 비용 승인 여부를 확인한 뒤 `terraform apply` 해야 한다.
