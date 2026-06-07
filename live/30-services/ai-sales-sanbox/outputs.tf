output "openai_id" { value = try(azurerm_cognitive_account.openai[0].id, null) }
output "search_id" { value = try(azurerm_search_service.search[0].id, null) }
output "storage_id" { value = try(azurerm_storage_account.storage[0].id, null) }
output "keyvault_id" { value = try(azurerm_key_vault.kv[0].id, null) }
output "private_endpoint_ids" { value = { openai=try(azurerm_private_endpoint.openai[0].id,null), search=try(azurerm_private_endpoint.search[0].id,null), blob=try(azurerm_private_endpoint.blob[0].id,null), keyvault=try(azurerm_private_endpoint.keyvault[0].id,null) } }
