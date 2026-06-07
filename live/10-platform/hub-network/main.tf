module "hub" {
  source = "../../../modules/network_hub"

  name                        = var.hub_name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  address_space               = var.address_space
  dns_servers                 = var.dns_servers
  subnets                     = var.subnets
  enable_private_dns_resolver = var.enable_private_dns_resolver
  dns_inbound_subnet_key      = var.dns_inbound_subnet_key
  dns_outbound_subnet_key     = var.dns_outbound_subnet_key
  tags                        = var.common_tags
}
