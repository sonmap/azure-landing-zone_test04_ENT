output "vnet_id" { value = azurerm_virtual_network.hub.id }
output "vnet_name" { value = azurerm_virtual_network.hub.name }
output "subnet_ids" { value = { for k, v in azurerm_subnet.subnets : k => v.id } }
output "dns_inbound_endpoint_ip" {
  value = try(azurerm_private_dns_resolver_inbound_endpoint.this[0].ip_configurations[0].private_ip_address, null)
}
