variable "tenant_id" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
variable "private_endpoint_subnet_id" { type = string }
variable "create_private_endpoints" {
  type    = bool
  default = true
}

variable "enable_openai" {
  type    = bool
  default = true
}
variable "openai_name" { type = string }
variable "openai_sku_name" {
  type    = string
  default = "S0"
}
variable "openai_custom_subdomain_name" { type = string }
variable "openai_private_dns_zone_ids" {
  type    = list(string)
  default = []
}

variable "enable_search" {
  type    = bool
  default = true
}
variable "search_name" { type = string }
variable "search_sku" {
  type    = string
  default = "basic"
}
variable "search_private_dns_zone_ids" {
  type    = list(string)
  default = []
}

variable "enable_storage" {
  type    = bool
  default = true
}
variable "storage_name" { type = string }
variable "storage_replication_type" {
  type    = string
  default = "LRS"
}
variable "blob_private_dns_zone_ids" {
  type    = list(string)
  default = []
}

variable "enable_key_vault" {
  type    = bool
  default = true
}
variable "key_vault_name" { type = string }
variable "key_vault_sku" {
  type    = string
  default = "standard"
}
variable "keyvault_private_dns_zone_ids" {
  type    = list(string)
  default = []
}
