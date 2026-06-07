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
variable "firewall_policy_id" { type = string }
variable "rule_collection_group_name" { type = string }
variable "priority" {
  type    = number
  default = 100
}
variable "network_rule_collections" {
  type    = any
  default = {}
}
variable "application_rule_collections" {
  type    = any
  default = {}
}
