variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "dns_prefix" { type = string }
variable "kubernetes_version" {
  type    = string
  default = null
}
variable "sku_tier" {
  type    = string
  default = "Free"
}
variable "subnet_id" { type = string }
variable "network_plugin" {
  type    = string
  default = "azure"
}
variable "network_policy" {
  type    = string
  default = "azure"
}
variable "service_cidr" { type = string }
variable "dns_service_ip" { type = string }
variable "outbound_type" {
  type    = string
  default = "userDefinedRouting"
}
variable "admin_group_object_ids" {
  type    = list(string)
  default = []
}
variable "log_analytics_workspace_id" { type = string }
variable "create_acr" {
  type    = bool
  default = true
}
variable "acr_name" { type = string }
variable "acr_sku" {
  type    = string
  default = "Premium"
}
variable "tags" {
  type    = map(string)
  default = {}
}

variable "default_node_pool" {
  type = object({
    name                 = string
    vm_size              = string
    node_count           = optional(number, 2)
    auto_scaling_enabled = optional(bool, true)
    min_count            = optional(number, 2)
    max_count            = optional(number, 5)
    os_disk_size_gb      = optional(number, 128)
  })
}

variable "user_node_pools" {
  type = map(object({
    name                 = string
    vm_size              = string
    node_count           = optional(number, 1)
    auto_scaling_enabled = optional(bool, true)
    min_count            = optional(number, 1)
    max_count            = optional(number, 5)
    os_disk_size_gb      = optional(number, 128)
  }))
  default = {}
}
