output "vm_ids" {
  description = "VM ID 목록"
  value = {
    for k, v in azurerm_linux_virtual_machine.this :
    k => v.id
  }
}

output "vm_names" {
  description = "VM 이름 목록"
  value = {
    for k, v in azurerm_linux_virtual_machine.this :
    k => v.name
  }
}

output "private_ips" {
  description = "VM Private IP 목록"
  value = {
    for k, v in azurerm_network_interface.this :
    k => v.private_ip_address
  }
}

output "nic_ids" {
  description = "NIC ID 목록"
  value = {
    for k, v in azurerm_network_interface.this :
    k => v.id
  }
}

output "data_disk_ids" {
  description = "Data Disk ID 목록"
  value = {
    for k, v in azurerm_managed_disk.data :
    k => v.id
  }
}

output "data_disk_names" {
  description = "Data Disk 이름 목록"
  value = {
    for k, v in azurerm_managed_disk.data :
    k => v.name
  }
}

output "ansible_inventory_ini" {
  description = "간단한 Ansible inventory 예시"
  value = join("\n", concat(
    ["[web]"],
    [for k, vm in var.web_vms : "${vm.name} ansible_host=${vm.private_ip_address}"],
    [""],
    ["[was]"],
    [for k, vm in var.was_vms : "${vm.name} ansible_host=${vm.private_ip_address}"],
    [""],
    ["[db]"],
    [for k, vm in var.db_vms : "${vm.name} ansible_host=${vm.private_ip_address}"],
    [""],
    ["[agent]"],
    [for k, vm in var.agent_vms : "${vm.name} ansible_host=${vm.private_ip_address}"],
    [""],
    ["[all:vars]"],
    ["ansible_user=${var.admin_username}"]
  ))
}
