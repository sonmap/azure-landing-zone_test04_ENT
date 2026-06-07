module "private_endpoint" {
  source = "../../../modules/private_endpoint"

  name                           = var.pe_name
  location                       = var.location
  resource_group_name            = var.resource_group_name
  subnet_id                      = var.subnet_id
  private_connection_resource_id = var.private_connection_resource_id
  subresource_names              = var.subresource_names
  private_dns_zone_ids           = var.private_dns_zone_ids
  tags                           = var.common_tags
}
