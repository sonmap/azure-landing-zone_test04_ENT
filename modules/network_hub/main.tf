resource "azurerm_virtual_network" "hub" {
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
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = each.value.address_prefixes

  dynamic "delegation" {
    for_each = try(each.value.delegate_dns_resolver, false) ? [1] : []

    content {
      name = "Microsoft.Network.dnsResolvers"

      service_delegation {
        name    = "Microsoft.Network/dnsResolvers"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
  }
}

resource "azurerm_network_security_group" "nsg" {
  for_each = { for k, s in var.subnets : k => s if try(s.create_nsg, false) }

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

resource "azurerm_private_dns_resolver" "this" {
  count = var.enable_private_dns_resolver ? 1 : 0

  name                = "pdnsr-${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  virtual_network_id  = azurerm_virtual_network.hub.id
  tags                = var.tags
}

resource "azurerm_private_dns_resolver_inbound_endpoint" "this" {
  count = var.enable_private_dns_resolver && var.dns_inbound_subnet_key != null ? 1 : 0

  name                    = "in-${var.name}"
  private_dns_resolver_id = azurerm_private_dns_resolver.this[0].id
  location                = var.location

  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = azurerm_subnet.subnets[var.dns_inbound_subnet_key].id
  }
}

resource "azurerm_private_dns_resolver_outbound_endpoint" "this" {
  count = var.enable_private_dns_resolver && var.dns_outbound_subnet_key != null ? 1 : 0

  name                    = "out-${var.name}"
  private_dns_resolver_id = azurerm_private_dns_resolver.this[0].id
  location                = var.location
  subnet_id               = azurerm_subnet.subnets[var.dns_outbound_subnet_key].id
}
