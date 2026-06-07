output "resource_group_name" { value = azurerm_resource_group.workload.name }
output "vnet_id" { value = module.spoke.vnet_id }
output "vnet_name" { value = module.spoke.vnet_name }
output "subnet_ids" { value = module.spoke.subnet_ids }
output "route_table_id" { value = module.spoke.route_table_id }
