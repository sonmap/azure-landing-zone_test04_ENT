output "openai_id" { value = try(azurerm_cognitive_account.openai[0].id, null) }
output "search_id" { value = try(azurerm_search_service.search[0].id, null) }
output "storage_id" { value = try(azurerm_storage_account.storage[0].id, null) }
output "key_vault_id" { value = try(azurerm_key_vault.kv[0].id, null) }
