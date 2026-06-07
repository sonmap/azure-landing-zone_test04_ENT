output "application_gateway_private_ip" { value = try(azurerm_application_gateway.web[0].frontend_ip_configuration[0].private_ip_address, null) }
output "vm_private_ips" { value = { for k, v in local.all_vms : k => v.private_ip_address } }
output "ansible_inventory" { value = local_file.ansible_inventory.filename }
