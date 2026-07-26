# Excel 설계 파일 위치

다음 명령으로 실제 설계용 Excel 파일을 생성합니다.

```powershell
python .\tools\create_excel_design_template.py `
  --output .\design\azure_landingzone_design.xlsx
```

실제 `.xlsx` 설계서는 내부 IP, Subscription/Tenant 식별자, 담당자 등의 정보가 포함될 수 있으므로 저장소의 `.gitignore` 정책에 따라 커밋하지 않습니다.

Excel을 수정한 후 `tools/generate_design_tfvars.ps1` 또는 `tools/generate_design_tfvars.sh`를 실행하여 Root별 `10-design.auto.tfvars.json`을 생성합니다.
