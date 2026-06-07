variable "resource_group_name" {
  description = "VM을 생성할 Resource Group 이름"
  type        = string
}

variable "location" {
  description = "Azure Region"
  type        = string
}

variable "vnet_resource_group_name" {
  description = "VNet이 존재하는 Resource Group 이름"
  type        = string
}

variable "vnet_name" {
  description = "VM이 연결될 VNet 이름"
  type        = string
}

variable "admin_username" {
  description = "Linux VM 관리자 계정"
  type        = string
}

variable "ssh_public_key" {
  description = "Linux VM 접속용 SSH Public Key"
  type        = string
  sensitive   = true
}

variable "image_publisher" {
  description = "OS Image Publisher"
  type        = string
}

variable "image_offer" {
  description = "OS Image Offer"
  type        = string
}

variable "image_sku" {
  description = "OS Image SKU"
  type        = string
}

variable "image_version" {
  description = "OS Image Version"
  type        = string
  default     = "latest"
}

variable "os_disk_storage_type" {
  description = "OS Disk Storage Type"
  type        = string
  default     = "Premium_LRS"
}

variable "common_tags" {
  description = "모든 VM에 공통 적용할 Tag"
  type        = map(string)
  default     = {}
}

variable "web_vms" {
  description = "WEB VM 목록"
  type = map(object({
    name               = string
    subnet_name        = string
    private_ip_address = string
    vm_size            = string
    os_disk_size_gb    = number
    role               = string
    itsm_ticket        = string
    data_disks = map(object({
      size_gb              = number
      storage_account_type = string
      lun                  = number
      caching              = string
    }))
  }))
  default = {}
}

variable "was_vms" {
  description = "WAS VM 목록"
  type = map(object({
    name               = string
    subnet_name        = string
    private_ip_address = string
    vm_size            = string
    os_disk_size_gb    = number
    role               = string
    itsm_ticket        = string
    data_disks = map(object({
      size_gb              = number
      storage_account_type = string
      lun                  = number
      caching              = string
    }))
  }))
  default = {}
}

variable "db_vms" {
  description = "DB VM 목록"
  type = map(object({
    name               = string
    subnet_name        = string
    private_ip_address = string
    vm_size            = string
    os_disk_size_gb    = number
    role               = string
    itsm_ticket        = string
    data_disks = map(object({
      size_gb              = number
      storage_account_type = string
      lun                  = number
      caching              = string
    }))
  }))
  default = {}
}

variable "agent_vms" {
  description = "DevOps/Ansible Agent VM 목록"
  type = map(object({
    name               = string
    subnet_name        = string
    private_ip_address = string
    vm_size            = string
    os_disk_size_gb    = number
    role               = string
    itsm_ticket        = string
    data_disks = map(object({
      size_gb              = number
      storage_account_type = string
      lun                  = number
      caching              = string
    }))
  }))
  default = {}
}
