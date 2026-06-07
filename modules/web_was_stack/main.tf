module "web" {
  for_each = var.web_vms
  source   = "../linux_vm"

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.web_subnet_id
  private_ip_address  = try(each.value.private_ip_address, null)
  vm_size             = each.value.vm_size
  admin_username      = var.admin_username
  ssh_public_key      = var.ssh_public_key
  os_disk_size_gb     = try(each.value.os_disk_size_gb, 128)
  image               = var.image
  data_disks          = try(each.value.data_disks, {})
  tags                = merge(var.tags, { role = "web" })
}

module "was" {
  for_each = var.was_vms
  source   = "../linux_vm"

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.was_subnet_id
  private_ip_address  = try(each.value.private_ip_address, null)
  vm_size             = each.value.vm_size
  admin_username      = var.admin_username
  ssh_public_key      = var.ssh_public_key
  os_disk_size_gb     = try(each.value.os_disk_size_gb, 128)
  image               = var.image
  data_disks          = try(each.value.data_disks, {})
  tags                = merge(var.tags, { role = "was" })
}

resource "azurerm_lb" "web_internal" {
  count = var.enable_internal_lb ? 1 : 0

  name                = "ilb-${var.name}-web"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  tags                = var.tags

  frontend_ip_configuration {
    name                          = "fe-web"
    subnet_id                     = var.web_subnet_id
    private_ip_address_allocation = var.lb_private_ip == null ? "Dynamic" : "Static"
    private_ip_address            = var.lb_private_ip
  }
}

resource "azurerm_lb_backend_address_pool" "web" {
  count = var.enable_internal_lb ? 1 : 0

  name            = "be-web"
  loadbalancer_id = azurerm_lb.web_internal[0].id
}

resource "azurerm_network_interface_backend_address_pool_association" "web" {
  for_each = var.enable_internal_lb ? module.web : {}

  network_interface_id    = each.value.network_interface_id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.web[0].id
}

resource "azurerm_lb_probe" "web" {
  count = var.enable_internal_lb ? 1 : 0

  name            = "probe-web-${var.lb_probe_port}"
  loadbalancer_id = azurerm_lb.web_internal[0].id
  protocol        = var.lb_probe_protocol
  port            = var.lb_probe_port
}

resource "azurerm_lb_rule" "web" {
  count = var.enable_internal_lb ? 1 : 0

  name                           = "rule-web-${var.lb_frontend_port}"
  loadbalancer_id                = azurerm_lb.web_internal[0].id
  protocol                       = "Tcp"
  frontend_port                  = var.lb_frontend_port
  backend_port                   = var.lb_backend_port
  frontend_ip_configuration_name = "fe-web"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.web[0].id]
  probe_id                       = azurerm_lb_probe.web[0].id
}
