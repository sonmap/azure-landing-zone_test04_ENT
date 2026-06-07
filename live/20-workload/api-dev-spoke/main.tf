resource "azurerm_resource_group" "workload" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.common_tags
}

module "spoke" {
  source = "../../../modules/workload_spoke"

  name                    = var.spoke_name
  location                = var.location
  resource_group_name     = azurerm_resource_group.workload.name
  address_space           = var.address_space
  dns_servers             = var.dns_servers
  hub_vnet_id             = var.hub_vnet_id
  hub_resource_group_name = var.hub_resource_group_name
  hub_vnet_name           = var.hub_vnet_name
  firewall_private_ip     = var.firewall_private_ip
  subnets                 = var.subnets
  tags                    = var.common_tags
}
