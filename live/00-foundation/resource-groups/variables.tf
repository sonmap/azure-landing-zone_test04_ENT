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
variable "resource_groups" {
  type = map(object({ name = string, location = string, tags = optional(map(string), {}) }))
}
