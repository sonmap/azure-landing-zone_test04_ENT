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

variable "subnets" {
  type = map(object({
    name                  = string
    address_prefixes      = list(string)
    create_nsg            = optional(bool, false)
    delegate_dns_resolver = optional(bool, false)
  }))
}

variable "enable_private_dns_resolver" {
  type    = bool
  default = false
}
variable "dns_inbound_subnet_key" {
  type    = string
  default = null
}
variable "dns_outbound_subnet_key" {
  type    = string
  default = null
}
