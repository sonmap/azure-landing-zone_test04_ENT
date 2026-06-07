resource "azurerm_cognitive_account" "openai" {
  count = var.enable_openai ? 1 : 0

  name                          = var.openai_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  kind                          = "OpenAI"
  sku_name                      = var.openai_sku_name
  public_network_access_enabled = false
  custom_subdomain_name         = var.openai_custom_subdomain_name
  tags                          = var.tags
}

resource "azurerm_search_service" "search" {
  count = var.enable_search ? 1 : 0

  name                          = var.search_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.search_sku
  public_network_access_enabled = false
  local_authentication_enabled  = false
  tags                          = var.tags
}

resource "azurerm_storage_account" "storage" {
  count = var.enable_storage ? 1 : 0

  name                            = var.storage_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = var.storage_replication_type
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = false
  shared_access_key_enabled       = false
  min_tls_version                 = "TLS1_2"
  tags                            = var.tags
}

resource "azurerm_key_vault" "kv" {
  count = var.enable_key_vault ? 1 : 0

  name                          = var.key_vault_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = var.tenant_id
  sku_name                      = var.key_vault_sku
  public_network_access_enabled = false
  rbac_authorization_enabled    = true
  purge_protection_enabled      = true
  soft_delete_retention_days    = 30
  tags                          = var.tags
}

module "pe_openai" {
  count  = var.enable_openai && var.create_private_endpoints ? 1 : 0
  source = "../private_endpoint"

  name                           = "pe-${var.openai_name}"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  subnet_id                      = var.private_endpoint_subnet_id
  private_connection_resource_id = azurerm_cognitive_account.openai[0].id
  subresource_names              = ["account"]
  private_dns_zone_ids           = var.openai_private_dns_zone_ids
  tags                           = var.tags
}

module "pe_search" {
  count  = var.enable_search && var.create_private_endpoints ? 1 : 0
  source = "../private_endpoint"

  name                           = "pe-${var.search_name}"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  subnet_id                      = var.private_endpoint_subnet_id
  private_connection_resource_id = azurerm_search_service.search[0].id
  subresource_names              = ["searchService"]
  private_dns_zone_ids           = var.search_private_dns_zone_ids
  tags                           = var.tags
}

module "pe_blob" {
  count  = var.enable_storage && var.create_private_endpoints ? 1 : 0
  source = "../private_endpoint"

  name                           = "pe-${var.storage_name}-blob"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  subnet_id                      = var.private_endpoint_subnet_id
  private_connection_resource_id = azurerm_storage_account.storage[0].id
  subresource_names              = ["blob"]
  private_dns_zone_ids           = var.blob_private_dns_zone_ids
  tags                           = var.tags
}

module "pe_kv" {
  count  = var.enable_key_vault && var.create_private_endpoints ? 1 : 0
  source = "../private_endpoint"

  name                           = "pe-${var.key_vault_name}"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  subnet_id                      = var.private_endpoint_subnet_id
  private_connection_resource_id = azurerm_key_vault.kv[0].id
  subresource_names              = ["vault"]
  private_dns_zone_ids           = var.keyvault_private_dns_zone_ids
  tags                           = var.tags
}
