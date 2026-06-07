variable "tenant_id" { type = string }
variable "subscription_id" { type = string }
variable "location" {
  type    = string
  default = "koreacentral"
}
variable "resource_group_name" { type = string }
variable "firewall_name" { type = string }
variable "firewall_subnet_id" { type = string }
variable "public_ip_name" { type = string }
variable "sku_tier" {
  type    = string
  default = "Standard"
}
variable "common_tags" {
  type    = map(string)
  default = {}
}
