variable "tenant_id" { type = string }
variable "subscription_id" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "vnet_resource_group_name" { type = string }
variable "vnet_name" { type = string }
variable "admin_username" { type = string }
variable "ssh_public_key" {
  type      = string
  sensitive = true
}
variable "image_publisher" {
  type    = string
  default = "RedHat"
}
variable "image_offer" {
  type    = string
  default = "RHEL"
}
variable "image_sku" {
  type    = string
  default = "9-lvm-gen2"
}
variable "image_version" {
  type    = string
  default = "latest"
}
variable "os_disk_storage_type" {
  type    = string
  default = "Premium_LRS"
}
variable "common_tags" {
  type    = map(string)
  default = {}
}
variable "app_gateway" {
  type = object({
    enabled            = bool
    name               = string
    subnet_name        = string
    private_ip_address = string
    frontend_port      = number
    backend_port       = number
    probe_path         = string
    sku_name           = string
    sku_tier           = string
    capacity           = number
  })
}
variable "web_vms" { type = map(object({ name = string, subnet_name = string, private_ip_address = string, vm_size = string, os_disk_size_gb = number, role = string, data_disks = map(any) })) }
variable "app_vms" {
  type = map(object({
    name               = string
    subnet_name        = string
    private_ip_address = string
    vm_size            = string
    os_disk_size_gb    = number
    role               = string
    data_disks = map(object({
      size_gb              = number
      storage_account_type = string
      lun                  = number
      caching              = string
    }))
  }))
}
variable "db_vms" {
  type = map(object({
    name               = string
    subnet_name        = string
    private_ip_address = string
    vm_size            = string
    os_disk_size_gb    = number
    role               = string
    data_disks = map(object({
      size_gb              = number
      storage_account_type = string
      lun                  = number
      caching              = string
    }))
  }))
}
