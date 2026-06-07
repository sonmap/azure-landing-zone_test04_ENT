# 최신 Enterprise Landing Zone 추가 항목 반영

Microsoft Azure Landing Zone, Well-Architected Framework, AVM 기반 운영 흐름을 기준으로 추가 검토 항목을 Excel 설계서에 반영했다.

## 추가된 Excel 시트

| 시트 | 목적 |
|---|---|
| `34_LZ_Vending_Request` | 신규 부서/업무 Landing Zone 자동 발급 요청 |
| `35_Pipeline_Governance` | Terraform pipeline gate, policy/cost/security check |
| `36_FinOps_CostGuard` | 예산, SKU 제한, 고비용 리소스 승인, TTL |
| `37_Defender_CSPM` | Defender for Cloud, CSPM, MCSB, Secure Score |
| `38_AzureArc_Hybrid` | 온프레미스 서버/Kubernetes Azure Arc 관리 |
| `39_Data_Governance` | 데이터 분류, Purview, DLP, retention, lineage |
| `40_DevSecOps_SupplyChain` | 이미지 스캔, SBOM, 서명, secret/dependency scan |
| `41_Resilience_DRTest` | DR drill, failover test, RTO/RPO 증적 |
| `42_Emergency_Access` | break-glass 계정, 비상 접근 승인/감사 |

## 운영 우선순위

1. `34_LZ_Vending_Request`
2. `35_Pipeline_Governance`
3. `36_FinOps_CostGuard`
4. `37_Defender_CSPM`
5. `38_AzureArc_Hybrid`
6. `39_Data_Governance`
7. `40_DevSecOps_SupplyChain`
8. `41_Resilience_DRTest`
9. `42_Emergency_Access`

## 매핑

각 시트의 `tfvars path`와 `선택 갱신 명령`은 `19_TFVars_Mapping`에 추가되어 있다.

운영 흐름:

```text
Excel 행 수정
→ 19_TFVars_Mapping에서 대상 확인
→ 선택 갱신 명령 실행
→ 출력된 Terraform root에서 terraform plan
→ 승인 후 terraform apply
```

## 참고

이 단계는 설계 항목과 운영 매핑을 Excel에 반영한 것이다. 실제 Terraform 모듈 구현은 우선순위에 따라 `LZ Vending`, `Pipeline Governance`, `FinOps`, `Defender CSPM`, `Azure Arc` 순서로 확장한다.
