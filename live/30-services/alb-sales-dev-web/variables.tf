variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "vnet_resource_group_name" { type = string }
variable "vnet_name" { type = string }
variable "subnet_name" { type = string }
variable "app_gateway_name" { type = string }
variable "frontend_private_ip" { type = string }
variable "backend_ip_addresses" { type = list(string) }
variable "probe" { type = object({ name = string, protocol = string, path = string, interval = number, timeout = number, unhealthy_threshold = number }) }
variable "listener" { type = object({ name = string, protocol = string, frontend_port = number }) }
variable "backend_http_settings" { type = object({ name = string, protocol = string, port = number, request_timeout = number }) }
variable "sku" { type = object({ name = string, tier = string, capacity = number }) }
variable "tags" {
  type    = map(string)
  default = {}
}
