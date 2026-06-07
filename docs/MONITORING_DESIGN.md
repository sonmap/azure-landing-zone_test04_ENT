# Monitoring / Dashboard / Alert 설계

Excel 설계서에 모니터링 상세 영역을 추가했다.

| 영역 | Excel 시트 | 내용 |
|---|---|---|
| 모니터링 요약 | 25_Monitoring_Alert | Workspace, Diagnostic, Sentinel, 기본 Metric Set |
| 대시보드 | 31_Monitoring_Dashboard | Azure Dashboard/Workbook, 기본 위젯, Metric Chart, Log Query |
| 메트릭 알람 | 32_Metric_Alert_Rule | Metric Namespace, Metric Name, Aggregation, Operator, Threshold, Severity |
| 알림 대상 | 33_ActionGroup_Notification | SMS, Email, Webhook/ITSM, 수신자, 업무시간 |

## 기본 대시보드 항목

공통 운영 대시보드:

`	ext
Availability
Cost
Security
Failed Deployments
Firewall Deny
Activity Log
`

업무별 대시보드:

`	ext
VM Status
CPU / Memory / Network
Load Balancer Probe Health
Application Gateway 5xx / Failed Request
Container App Replica / Request Count
AI Search Throttling
`

## 기본 알람 예시

`	ext
VM CPU > 80%, 15분
NLB Backend Probe < 90%, 5분
Application Gateway FailedRequests > 10, 15분
Azure Firewall rule hit/deny 급증
AI Search throttling > 5%, 15분
`

## 알림 채널

Action Group 기준으로 아래 채널을 설계한다.

`	ext
SMS
Email
Webhook / ITSM
Voice, 필요 시
`

SMS는 Azure Monitor Action Group의 SMS receiver를 기준으로 설계한다. 실제 발송 가능 국가/요금/제한은 운영 구독과 Azure Monitor 정책에서 최종 확인해야 한다.

## 운영 흐름

1. 31_Monitoring_Dashboard, 32_Metric_Alert_Rule, 33_ActionGroup_Notification에서 요청을 수정한다.
2. 19_TFVars_Mapping에서 해당 	fvars path와 선택 갱신 명령을 확인한다.
3. 변경 대상만 갱신한다.
4. 출력된 Terraform root에서 	erraform plan을 확인한다.
5. 승인 후 	erraform apply 한다.
