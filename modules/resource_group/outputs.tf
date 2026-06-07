output "resource_group_ids" {
  value = { for k, v in azurerm_resource_group.this : k => v.id }
}
output "resource_group_names" {
  value = { for k, v in azurerm_resource_group.this : k => v.name }
}
