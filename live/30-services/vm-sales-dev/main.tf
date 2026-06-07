locals {
  all_vms = merge(
    var.web_vms,
    var.was_vms,
    var.db_vms,
    var.agent_vms
  )
}

data "azurerm_subnet" "target" {
  for_each = local.all_vms

  name                 = each.value.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.vnet_resource_group_name
}

resource "azurerm_network_interface" "this" {
  for_each = local.all_vms

  name                = "nic-${each.value.name}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = data.azurerm_subnet.target[each.key].id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.private_ip_address
  }

  tags = merge(var.common_tags, {
    role        = each.value.role
    hostname    = each.value.name
    subnet      = each.value.subnet_name
    private_ip  = each.value.private_ip_address
    itsm_ticket = each.value.itsm_ticket
  })
}

resource "azurerm_linux_virtual_machine" "this" {
  for_each = local.all_vms

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = each.value.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.this[each.key].id
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    name                 = "osdisk-${each.value.name}"
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_storage_type
    disk_size_gb         = each.value.os_disk_size_gb
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  tags = merge(var.common_tags, {
    role        = each.value.role
    hostname    = each.value.name
    subnet      = each.value.subnet_name
    private_ip  = each.value.private_ip_address
    itsm_ticket = each.value.itsm_ticket
  })
}

locals {
  data_disks_flat = merge([
    for vm_key, vm in local.all_vms : {
      for disk_key, disk in vm.data_disks :
      "${vm_key}-${disk_key}" => {
        vm_key               = vm_key
        disk_key             = disk_key
        vm_name              = vm.name
        name                 = "disk-${vm.name}-${disk_key}"
        size_gb              = disk.size_gb
        storage_account_type = disk.storage_account_type
        lun                  = disk.lun
        caching              = disk.caching
        role                 = vm.role
        itsm_ticket          = vm.itsm_ticket
      }
    }
  ]...)
}

resource "azurerm_managed_disk" "data" {
  for_each = local.data_disks_flat

  name                 = each.value.name
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = each.value.storage_account_type
  create_option        = "Empty"
  disk_size_gb         = each.value.size_gb

  tags = merge(var.common_tags, {
    role        = each.value.role
    hostname    = each.value.vm_name
    disk_role   = each.value.disk_key
    disk_type   = "data"
    itsm_ticket = each.value.itsm_ticket
  })
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  for_each = local.data_disks_flat

  managed_disk_id    = azurerm_managed_disk.data[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.this[each.value.vm_key].id
  lun                = each.value.lun
  caching            = each.value.caching
}
