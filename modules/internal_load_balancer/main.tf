data "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  resource_group_name = var.vnet_resource_group_name
}

data "azurerm_subnet" "frontend" {
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.vnet_resource_group_name
}

resource "azurerm_lb" "this" {
  name                = var.lb_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = var.frontend_ip_name
    subnet_id                     = data.azurerm_subnet.frontend.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.frontend_private_ip
  }

  tags = var.tags
}

resource "azurerm_lb_backend_address_pool" "this" {
  loadbalancer_id = azurerm_lb.this.id
  name            = "be-${var.lb_name}"
}

resource "azurerm_lb_backend_address_pool_address" "this" {
  for_each                = var.backend_addresses
  name                    = each.value.name
  backend_address_pool_id = azurerm_lb_backend_address_pool.this.id
  virtual_network_id      = data.azurerm_virtual_network.this.id
  ip_address              = each.value.ip_address
}

resource "azurerm_lb_probe" "this" {
  loadbalancer_id = azurerm_lb.this.id
  name            = var.probe.name
  protocol        = var.probe.protocol
  port            = var.probe.port
}

resource "azurerm_lb_rule" "this" {
  loadbalancer_id                = azurerm_lb.this.id
  name                           = var.rule.name
  protocol                       = var.rule.protocol
  frontend_port                  = var.rule.frontend_port
  backend_port                   = var.rule.backend_port
  frontend_ip_configuration_name = var.frontend_ip_name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.this.id]
  probe_id                       = azurerm_lb_probe.this.id
}
