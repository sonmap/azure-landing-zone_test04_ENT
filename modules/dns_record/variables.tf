variable "resource_group_name" { type = string }
variable "zone_name" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
variable "a_records" {
  type = map(object({
    name    = string
    ttl     = optional(number, 300)
    records = list(string)
  }))
}
