module "firewall" {
  source = "../../../modules/azure_firewall"

  name                = var.firewall_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.firewall_subnet_id
  public_ip_name      = var.public_ip_name
  sku_tier            = var.sku_tier
  tags                = var.common_tags
}
