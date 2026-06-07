output "a_record_ids" { value = { for k, v in azurerm_private_dns_a_record.this : k => v.id } }
