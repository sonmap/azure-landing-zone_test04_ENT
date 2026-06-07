locals {
  all_vms = merge(var.web_vms, var.app_vms, var.db_vms)
  data_disks_flat = merge([
    for vm_key, vm in merge(var.app_vms, var.db_vms) : {
      for disk_key, disk in vm.data_disks : "${vm_key}-${disk_key}" => {
        vm_key               = vm_key
        vm_name              = vm.name
        name                 = "disk-${vm.name}-${disk_key}"
        size_gb              = disk.size_gb
        storage_account_type = disk.storage_account_type
        lun                  = disk.lun
        caching              = disk.caching
      }
    }
  ]...)
}

data "azurerm_subnet" "vm" {
  for_each             = local.all_vms
  name                 = each.value.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.vnet_resource_group_name
}

data "azurerm_subnet" "appgw" {
  count                = var.app_gateway.enabled ? 1 : 0
  name                 = var.app_gateway.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.vnet_resource_group_name
}

resource "azurerm_network_interface" "vm" {
  for_each            = local.all_vms
  name                = "nic-${each.value.name}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = data.azurerm_subnet.vm[each.key].id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.private_ip_address
  }

  tags = merge(var.common_tags, {
    role       = each.value.role
    hostname   = each.value.name
    private_ip = each.value.private_ip_address
  })
}

resource "azurerm_linux_virtual_machine" "vm" {
  for_each                        = local.all_vms
  name                            = each.value.name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = each.value.vm_size
  admin_username                  = var.admin_username
  network_interface_ids           = [azurerm_network_interface.vm[each.key].id]
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
    role       = each.value.role
    hostname   = each.value.name
    private_ip = each.value.private_ip_address
  })
}

resource "azurerm_managed_disk" "data" {
  for_each             = local.data_disks_flat
  name                 = each.value.name
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = each.value.storage_account_type
  create_option        = "Empty"
  disk_size_gb         = each.value.size_gb
  tags                 = merge(var.common_tags, { hostname = each.value.vm_name })
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  for_each           = local.data_disks_flat
  managed_disk_id    = azurerm_managed_disk.data[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.vm[each.value.vm_key].id
  lun                = each.value.lun
  caching            = each.value.caching
}

resource "azurerm_application_gateway" "web" {
  count               = var.app_gateway.enabled ? 1 : 0
  name                = var.app_gateway.name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku {
    name     = var.app_gateway.sku_name
    tier     = var.app_gateway.sku_tier
    capacity = var.app_gateway.capacity
  }

  gateway_ip_configuration {
    name      = "gwip-${var.app_gateway.name}"
    subnet_id = data.azurerm_subnet.appgw[0].id
  }

  frontend_ip_configuration {
    name                          = "fe-${var.app_gateway.name}"
    subnet_id                     = data.azurerm_subnet.appgw[0].id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.app_gateway.private_ip_address
  }

  frontend_port {
    name = "fp-${var.app_gateway.frontend_port}"
    port = var.app_gateway.frontend_port
  }

  backend_address_pool {
    name         = "be-web"
    ip_addresses = [for vm in values(var.web_vms) : vm.private_ip_address]
  }
  probe {
    name                = "probe-web"
    protocol            = "Http"
    host                = "127.0.0.1"
    path                = var.app_gateway.probe_path
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
  }

  backend_http_settings {
    name                  = "bhs-web"
    cookie_based_affinity = "Disabled"
    port                  = var.app_gateway.backend_port
    protocol              = "Http"
    request_timeout       = 30
    probe_name            = "probe-web"
  }

  http_listener {
    name                           = "lstn-web"
    frontend_ip_configuration_name = "fe-${var.app_gateway.name}"
    frontend_port_name             = "fp-${var.app_gateway.frontend_port}"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "rule-web"
    rule_type                  = "Basic"
    http_listener_name         = "lstn-web"
    backend_address_pool_name  = "be-web"
    backend_http_settings_name = "bhs-web"
    priority                   = 100
  }

  tags = var.common_tags
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../../../ansible/inventories/generated/inventory-preprod.ini"
  content = join("\n", concat(
    ["[web]"],
    [for vm in values(var.web_vms) : "${vm.name} ansible_host=${vm.private_ip_address}"],
    [""],
    ["[app]"],
    [for vm in values(var.app_vms) : "${vm.name} ansible_host=${vm.private_ip_address}"],
    [""],
    ["[db]"],
    [for vm in values(var.db_vms) : "${vm.name} ansible_host=${vm.private_ip_address}"],
    [""],
    ["[all:vars]"],
    ["ansible_user=${var.admin_username}"],
  ))
}
