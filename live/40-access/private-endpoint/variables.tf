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
variable "pe_name" { type = string }
variable "subnet_id" { type = string }
variable "private_connection_resource_id" { type = string }
variable "subresource_names" { type = list(string) }
variable "private_dns_zone_ids" {
  type    = list(string)
  default = []
}
