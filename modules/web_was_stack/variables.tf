variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "web_subnet_id" { type = string }
variable "was_subnet_id" { type = string }
variable "admin_username" { type = string }
variable "ssh_public_key" {
  type      = string
  sensitive = true
}
variable "tags" {
  type    = map(string)
  default = {}
}
variable "enable_internal_lb" {
  type    = bool
  default = true
}
variable "lb_private_ip" {
  type    = string
  default = null
}
variable "lb_frontend_port" {
  type    = number
  default = 443
}
variable "lb_backend_port" {
  type    = number
  default = 443
}
variable "lb_probe_port" {
  type    = number
  default = 443
}
variable "lb_probe_protocol" {
  type    = string
  default = "Tcp"
}

variable "image" {
  type    = object({ publisher = string, offer = string, sku = string, version = string })
  default = { publisher = "RedHat", offer = "RHEL", sku = "9-lvm", version = "latest" }
}

variable "web_vms" {
  type = map(object({
    name               = string
    vm_size            = string
    private_ip_address = optional(string)
    os_disk_size_gb    = optional(number)
    data_disks = optional(map(object({
      size_gb              = number
      lun                  = number
      caching              = optional(string, "ReadWrite")
      storage_account_type = optional(string, "Premium_LRS")
    })), {})
  }))
}

variable "was_vms" {
  type = map(object({
    name               = string
    vm_size            = string
    private_ip_address = optional(string)
    os_disk_size_gb    = optional(number)
    data_disks = optional(map(object({
      size_gb              = number
      lun                  = number
      caching              = optional(string, "ReadWrite")
      storage_account_type = optional(string, "Premium_LRS")
    })), {})
  }))
}
