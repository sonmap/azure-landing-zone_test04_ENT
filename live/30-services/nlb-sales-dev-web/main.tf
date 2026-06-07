module "nlb" {
  source                   = "../../../modules/internal_load_balancer"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  vnet_resource_group_name = var.vnet_resource_group_name
  vnet_name                = var.vnet_name
  subnet_name              = var.subnet_name
  lb_name                  = var.lb_name
  frontend_ip_name         = var.frontend_ip_name
  frontend_private_ip      = var.frontend_private_ip
  backend_addresses        = var.backend_addresses
  probe                    = var.probe
  rule                     = var.rule
  tags                     = var.tags
}
