output "vnet_id" { value = azurerm_virtual_network.spoke.id }
output "vnet_name" { value = azurerm_virtual_network.spoke.name }
output "subnet_ids" { value = { for k, v in azurerm_subnet.subnets : k => v.id } }
output "route_table_id" { value = try(azurerm_route_table.rt[0].id, null) }
