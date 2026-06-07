output "aks_id" { value = azurerm_kubernetes_cluster.this.id }
output "aks_name" { value = azurerm_kubernetes_cluster.this.name }
output "private_fqdn" { value = azurerm_kubernetes_cluster.this.private_fqdn }
output "acr_id" { value = try(azurerm_container_registry.this[0].id, null) }
output "acr_login_server" { value = try(azurerm_container_registry.this[0].login_server, null) }
