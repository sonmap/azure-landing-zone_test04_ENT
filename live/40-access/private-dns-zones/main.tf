module "private_dns_zones" {
  source = "../../../modules/private_dns_zones"

  resource_group_name   = var.resource_group_name
  zones                 = var.zones
  virtual_network_links = var.virtual_network_links
  tags                  = var.common_tags
}
