output "vm_private_ips" { value={for k,v in azurerm_network_interface.vm:k=>v.private_ip_address} }
output "internal_lb_private_ip" { value=try(azurerm_lb.internal[0].frontend_ip_configuration[0].private_ip_address,null) }
output "ansible_inventory_file" { value=local_file.ansible_inventory.filename }
