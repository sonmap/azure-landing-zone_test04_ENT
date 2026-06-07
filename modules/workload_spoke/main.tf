resource "azurerm_virtual_network" "spoke" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  dns_servers         = var.dns_servers
  tags                = var.tags
}

resource "azurerm_subnet" "subnets" {
  for_each = var.subnets

  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = each.value.address_prefixes

  private_endpoint_network_policies = try(each.value.private_endpoint_network_policies, null)
}

resource "azurerm_network_security_group" "nsg" {
  for_each = { for k, s in var.subnets : k => s if try(s.create_nsg, true) }

  name                = "nsg-${each.value.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "assoc" {
  for_each = azurerm_network_security_group.nsg

  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = each.value.id
}

resource "azurerm_route_table" "rt" {
  count = var.create_route_table ? 1 : 0

  name                = "rt-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_route" "default_to_firewall" {
  count = var.create_route_table && var.firewall_private_ip != null ? 1 : 0

  name                   = "default-to-firewall"
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.rt[0].name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.firewall_private_ip
}

resource "azurerm_subnet_route_table_association" "rt_assoc" {
  for_each = var.create_route_table ? { for k, s in var.subnets : k => s if try(s.associate_route_table, true) } : {}

  subnet_id      = azurerm_subnet.subnets[each.key].id
  route_table_id = azurerm_route_table.rt[0].id
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  count = var.hub_vnet_id != null ? 1 : 0

  name                         = "peer-${var.name}-to-hub"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.spoke.name
  remote_virtual_network_id    = var.hub_vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = var.use_remote_gateways
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  count = var.hub_vnet_id != null && var.hub_resource_group_name != null && var.hub_vnet_name != null ? 1 : 0

  name                         = "peer-hub-to-${var.name}"
  resource_group_name          = var.hub_resource_group_name
  virtual_network_name         = var.hub_vnet_name
  remote_virtual_network_id    = azurerm_virtual_network.spoke.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}
