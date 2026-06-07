output "zone_ids" { value = { for k, v in azurerm_private_dns_zone.this : k => v.id } }
output "zone_names" { value = { for k, v in azurerm_private_dns_zone.this : k => v.name } }
