variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "subnet_id" { type = string }
variable "private_ip_address" {
  type    = string
  default = null
}
variable "vm_size" { type = string }
variable "admin_username" { type = string }
variable "ssh_public_key" {
  type      = string
  sensitive = true
}
variable "os_disk_size_gb" {
  type    = number
  default = 128
}
variable "os_disk_storage_account_type" {
  type    = string
  default = "Premium_LRS"
}
variable "tags" {
  type    = map(string)
  default = {}
}

variable "image" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "9-lvm"
    version   = "latest"
  }
}

variable "data_disks" {
  type = map(object({
    size_gb              = number
    lun                  = number
    caching              = optional(string, "ReadWrite")
    storage_account_type = optional(string, "Premium_LRS")
  }))
  default = {}
}
