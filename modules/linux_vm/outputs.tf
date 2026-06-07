output "vm_id" { value = azurerm_linux_virtual_machine.this.id }
output "vm_name" { value = azurerm_linux_virtual_machine.this.name }
output "private_ip_address" { value = azurerm_network_interface.this.private_ip_address }
output "identity_principal_id" { value = azurerm_linux_virtual_machine.this.identity[0].principal_id }
output "network_interface_id" { value = azurerm_network_interface.this.id }
