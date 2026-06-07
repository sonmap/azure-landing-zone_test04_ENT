variable "tenant_id" { type = string }
variable "subscription_id" { type = string }
variable "location" {
  type    = string
  default = "koreacentral"
}
variable "common_tags" {
  type    = map(string)
  default = {}
}
variable "resource_group_name" { type = string }
variable "hub_name" { type = string }
variable "address_space" { type = list(string) }
variable "dns_servers" {
  type    = list(string)
  default = []
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
  default = true
}
variable "dns_inbound_subnet_key" {
  type    = string
  default = "dns_in"
}
variable "dns_outbound_subnet_key" {
  type    = string
  default = "dns_out"
}
