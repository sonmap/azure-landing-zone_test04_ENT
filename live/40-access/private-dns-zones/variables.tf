variable "tenant_id" { type = string }
variable "subscription_id" { type = string }
variable "resource_group_name" { type = string }
variable "zones" { type = set(string) }
variable "virtual_network_links" {
  type = map(object({
    zone_name            = string
    name                 = string
    virtual_network_id   = string
    registration_enabled = optional(bool, false)
  }))
  default = {}
}
variable "common_tags" {
  type    = map(string)
  default = {}
}
