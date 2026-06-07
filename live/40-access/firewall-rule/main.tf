module "firewall_rule" {
  source = "../../../modules/firewall_rule"

  name                         = var.rule_collection_group_name
  firewall_policy_id           = var.firewall_policy_id
  priority                     = var.priority
  network_rule_collections     = var.network_rule_collections
  application_rule_collections = var.application_rule_collections
}
