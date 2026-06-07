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
variable "zone_name" { type = string }
variable "a_records" { type = map(object({ name = string, ttl = optional(number, 300), records = list(string) })) }
