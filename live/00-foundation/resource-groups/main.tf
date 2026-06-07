module "resource_groups" {
  source          = "../../../modules/resource_group"
  resource_groups = var.resource_groups
  common_tags     = var.common_tags
}
