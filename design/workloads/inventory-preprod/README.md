# Inventory Preprod Excel → Terraform → Ansible 샘플

## 포함 내용

- `inventory_preprod_terraform_ansible_design.xlsx`
  - Excel 설계 입력값
  - Subnet, VM, App Gateway, NSG, Ansible AP 배포 정보 포함

- `terraform/live/20-workload/inventory-preprod-spoke/terraform.tfvars`
  - VNet/Subnet/NSG/Route/Peering 입력값 샘플

- `terraform/live/30-services/inventory-preprod-stack/terraform.tfvars`
  - Web 2대, AP 2대, SQL 1대, Application Gateway 입력값 샘플

- `ansible/inventories/generated/inventory-preprod.ini`
  - Web/AP/DB Inventory 샘플

- `ansible/playbooks/deploy_inventory_app.yml`
  - AP 서버 2대에 샘플 Inventory API 배포 Playbook

## 적용 순서

1. Excel 값 검토
2. Terraform tfvars 생성 또는 샘플 tfvars 수정
3. Spoke 배포
4. Stack 배포
5. Ansible AP 배포

## Ansible 실행 예시

```bash
cd ~/azure_land06/ansible
ansible-playbook -i inventories/generated/inventory-preprod.ini playbooks/deploy_inventory_app.yml
```
