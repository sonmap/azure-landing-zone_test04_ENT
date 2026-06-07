module "dns_record" {
  source = "../../../modules/dns_record"

  resource_group_name = var.resource_group_name
  zone_name           = var.zone_name
  a_records           = var.a_records
  tags                = var.common_tags
}
