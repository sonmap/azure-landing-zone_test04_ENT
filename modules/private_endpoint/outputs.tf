output "private_endpoint_id" { value = azurerm_private_endpoint.this.id }
output "network_interface_id" { value = azurerm_private_endpoint.this.network_interface[0].id }
