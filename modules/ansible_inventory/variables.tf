variable "output_path" { type = string }
variable "groups" {
  type = map(list(object({
    name         = string
    ip           = string
    ansible_user = string
  })))
}
