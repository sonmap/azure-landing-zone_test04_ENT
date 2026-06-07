variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "vnet_resource_group_name" { type = string }
variable "vnet_name" { type = string }
variable "subnet_name" { type = string }
variable "lb_name" { type = string }
variable "frontend_ip_name" { type = string }
variable "frontend_private_ip" { type = string }
variable "backend_addresses" { type = map(object({ name = string, ip_address = string })) }
variable "probe" { type = object({ name = string, protocol = string, port = number }) }
variable "rule" { type = object({ name = string, protocol = string, frontend_port = number, backend_port = number }) }
variable "tags" {
  type    = map(string)
  default = {}
}
