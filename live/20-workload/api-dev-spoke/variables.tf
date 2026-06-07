variable "tenant_id" { type = string }
variable "subscription_id" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "spoke_name" { type = string }
variable "address_space" { type = list(string) }
variable "dns_servers" {
  type    = list(string)
  default = []
}
variable "hub_vnet_id" {
  type    = string
  default = null
}
variable "hub_resource_group_name" {
  type    = string
  default = null
}
variable "hub_vnet_name" {
  type    = string
  default = null
}
variable "firewall_private_ip" {
  type    = string
  default = null
}
variable "common_tags" {
  type    = map(string)
  default = {}
}
variable "subnets" {
  type = map(object({
    name                              = string
    address_prefixes                  = list(string)
    create_nsg                        = optional(bool, true)
    associate_route_table             = optional(bool, true)
    private_endpoint_network_policies = optional(string)
  }))
}
