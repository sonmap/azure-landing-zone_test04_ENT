variable "resource_group_name" { type=string }
variable "location" { type=string }
variable "tags" { type=map(string) default={} }
variable "vnet_resource_group_name" { type=string }
variable "vnet_name" { type=string }
variable "aks_subnet_name" { type=string }
variable "cluster" { type=object({ name=string, kubernetes_version=string, dns_prefix=string, private_cluster_enabled=bool, sku_tier=string, local_account_disabled=bool }) }
variable "default_node_pool" { type=object({ name=string, vm_size=string, node_count=number, auto_scaling_enabled=bool, min_count=number, max_count=number, os_disk_size_gb=number }) }
variable "user_node_pools" { type=map(object({ name=string, vm_size=string, mode=string, auto_scaling_enabled=bool, node_count=number, min_count=number, max_count=number, os_disk_size_gb=number })) default={} }
variable "network_profile" { type=object({ network_plugin=string, network_policy=string, service_cidr=string, dns_service_ip=string, outbound_type=string }) }
variable "monitoring" { type=object({ enabled=bool, log_analytics_workspace_id=string }) }
