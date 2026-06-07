# Inventory Preprod 샘플 시스템 Runbook

## 구성

```text
Application Gateway
  -> Web VM 2대
  -> AP/WAS VM 2대
  -> SQL VM 1대
```

## 파일 위치

업무별 Excel:

```text
design/workloads/inventory-preprod/inventory-preprod_design.xlsx
```

Terraform:

```text
live/20-workload/inventory-preprod-spoke
live/30-services/inventory-preprod-stack
```

Ansible:

```text
ansible/inventories/generated/inventory-preprod.ini
ansible/playbooks/deploy_inventory_app.yml
```

## 배포 순서

Spoke:

```bash
cd /home/son/azure_land06
tools/tf_root.sh live/20-workload/inventory-preprod-spoke plan
tools/tf_root.sh live/20-workload/inventory-preprod-spoke apply
```

Stack:

```bash
cd /home/son/azure_land06
tools/tf_root.sh live/30-services/inventory-preprod-stack plan
tools/tf_root.sh live/30-services/inventory-preprod-stack apply
```

Ansible AP 배포:

```bash
cd /home/son/azure_land06/ansible
ansible-playbook -i inventories/generated/inventory-preprod.ini playbooks/deploy_inventory_app.yml
```

## TTL

`tools/tf_root.sh apply`를 사용하면 기본적으로 1시간 뒤 전체 non-prod destroy가 예약된다.

Inventory preprod는 prod가 아니므로 TTL destroy 대상이다.

## 주의

`terraform.tfvars`의 `ssh_public_key`는 실제 public key로 교체해야 한다.
