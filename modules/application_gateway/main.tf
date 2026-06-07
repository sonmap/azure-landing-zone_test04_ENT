data "azurerm_subnet" "appgw" {
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.vnet_resource_group_name
}

resource "azurerm_application_gateway" "this" {
  name                = var.app_gateway_name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku {
    name     = var.sku.name
    tier     = var.sku.tier
    capacity = var.sku.capacity
  }

  gateway_ip_configuration {
    name      = "gwip-${var.app_gateway_name}"
    subnet_id = data.azurerm_subnet.appgw.id
  }

  frontend_ip_configuration {
    name                          = "fe-${var.app_gateway_name}"
    subnet_id                     = data.azurerm_subnet.appgw.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.frontend_private_ip
  }

  frontend_port {
    name = "fp-${var.listener.frontend_port}"
    port = var.listener.frontend_port
  }

  backend_address_pool {
    name         = "be-${var.app_gateway_name}"
    ip_addresses = var.backend_ip_addresses
  }

  probe {
    name                = var.probe.name
    protocol            = var.probe.protocol
    path                = var.probe.path
    interval            = var.probe.interval
    timeout             = var.probe.timeout
    unhealthy_threshold = var.probe.unhealthy_threshold
  }

  backend_http_settings {
    name                  = var.backend_http_settings.name
    cookie_based_affinity = "Disabled"
    port                  = var.backend_http_settings.port
    protocol              = var.backend_http_settings.protocol
    request_timeout       = var.backend_http_settings.request_timeout
    probe_name            = var.probe.name
  }

  http_listener {
    name                           = var.listener.name
    frontend_ip_configuration_name = "fe-${var.app_gateway_name}"
    frontend_port_name             = "fp-${var.listener.frontend_port}"
    protocol                       = var.listener.protocol
  }

  request_routing_rule {
    name                       = "rule-${var.app_gateway_name}"
    rule_type                  = "Basic"
    http_listener_name         = var.listener.name
    backend_address_pool_name  = "be-${var.app_gateway_name}"
    backend_http_settings_name = var.backend_http_settings.name
    priority                   = 100
  }

  tags = var.tags
}
