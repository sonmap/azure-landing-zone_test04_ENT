variable "resource_group_name" { type=string }
variable "location" { type=string }
variable "tags" { type=map(string) default={} }
variable "vnet_resource_group_name" { type=string }
variable "vnet_name" { type=string }
variable "admin_username" { type=string }
variable "ssh_public_key" { type=string sensitive=true }
variable "image_publisher" { type=string }
variable "image_offer" { type=string }
variable "image_sku" { type=string }
variable "image_version" { type=string default="latest" }
variable "os_disk_storage_type" { type=string default="Premium_LRS" }
variable "web_vms" { type=map(object({ name=string, subnet_name=string, private_ip_address=string, vm_size=string, os_disk_size_gb=number })) default={} }
variable "was_vms" { type=map(object({ name=string, subnet_name=string, private_ip_address=string, vm_size=string, os_disk_size_gb=number, data_disks=map(object({ size_gb=number, storage_account_type=string, lun=number, caching=string })) })) default={} }
variable "internal_lb" { type=object({ enabled=bool, name=string, frontend_ip_name=string, frontend_private_ip=string, subnet_name=string, probe_port=number, lb_rule_port=number, backend_port=number }) }
