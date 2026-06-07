output "aks_id" { value = azurerm_kubernetes_cluster.this.id }
output "aks_name" { value = azurerm_kubernetes_cluster.this.name }
output "private_fqdn" { value = azurerm_kubernetes_cluster.this.private_fqdn }
output "kube_config_command" { value = "az aks get-credentials -g ${var.resource_group_name} -n ${azurerm_kubernetes_cluster.this.name} --overwrite-existing" }
