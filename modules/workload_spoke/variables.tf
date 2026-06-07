variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "address_space" { type = list(string) }
variable "dns_servers" {
  type    = list(string)
  default = []
}
variable "tags" {
  type    = map(string)
  default = {}
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
variable "use_remote_gateways" {
  type    = bool
  default = false
}
variable "create_route_table" {
  type    = bool
  default = true
}
variable "firewall_private_ip" {
  type    = string
  default = null
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
