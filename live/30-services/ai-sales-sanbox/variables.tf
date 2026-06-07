variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tags" { type = map(string) default = {} }
variable "vnet_resource_group_name" { type = string }
variable "vnet_name" { type = string }
variable "private_endpoint_subnet_name" { type = string }
variable "private_dns_zone_resource_group_name" { type = string }
variable "openai" { type = object({ enabled=bool, name=string, sku_name=string, public_network_access=string, custom_subdomain_name=optional(string) }) }
variable "search" { type = object({ enabled=bool, name=string, sku=string, replica_count=number, partition_count=number, public_network_access=string }) }
variable "storage" { type = object({ enabled=bool, name=string, account_tier=string, account_replication_type=string, public_network_access=string, allow_blob_public_access=bool, default_action=string, containers=list(string) }) }
variable "keyvault" { type = object({ enabled=bool, name=string, sku_name=string, tenant_id=string, public_network_access=string, purge_protection=bool }) }
variable "private_endpoints" { type = object({ openai=bool, search=bool, blob=bool, keyvault=bool }) }
variable "private_dns_zones" { type = object({ openai=string, search=string, blob=string, keyvault=string }) }
