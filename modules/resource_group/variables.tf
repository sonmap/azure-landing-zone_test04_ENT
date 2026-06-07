variable "resource_groups" {
  description = "Map of resource groups to create."
  type = map(object({
    name     = string
    location = string
    tags     = optional(map(string), {})
  }))
}

variable "common_tags" {
  type    = map(string)
  default = {}
}
