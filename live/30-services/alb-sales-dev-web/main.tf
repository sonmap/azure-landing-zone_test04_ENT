module "alb" {
  source                   = "../../../modules/application_gateway"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  vnet_resource_group_name = var.vnet_resource_group_name
  vnet_name                = var.vnet_name
  subnet_name              = var.subnet_name
  app_gateway_name         = var.app_gateway_name
  frontend_private_ip      = var.frontend_private_ip
  backend_ip_addresses     = var.backend_ip_addresses
  probe                    = var.probe
  listener                 = var.listener
  backend_http_settings    = var.backend_http_settings
  sku                      = var.sku
  tags                     = var.tags
}
