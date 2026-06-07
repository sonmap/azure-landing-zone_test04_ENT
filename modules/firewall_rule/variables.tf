variable "name" { type = string }
variable "firewall_policy_id" { type = string }
variable "priority" {
  type    = number
  default = 100
}

variable "network_rule_collections" {
  type = map(object({
    name     = string
    priority = number
    action   = string
    rules = map(object({
      name                  = string
      protocols             = list(string)
      source_addresses      = list(string)
      destination_addresses = list(string)
      destination_ports     = list(string)
    }))
  }))
  default = {}
}

variable "application_rule_collections" {
  type = map(object({
    name     = string
    priority = number
    action   = string
    rules = map(object({
      name              = string
      source_addresses  = list(string)
      protocol_type     = string
      protocol_port     = number
      destination_fqdns = list(string)
    }))
  }))
  default = {}
}
