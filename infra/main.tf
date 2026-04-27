resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

data "azurerm_dns_zone" "public" {
  count               = local.dns_zone_enabled ? 1 : 0
  name                = var.dns_zone_name
  resource_group_name = var.dns_zone_resource_group_name
}

resource "azurerm_static_web_app" "this" {
  name                               = var.static_web_app_name
  resource_group_name                = azurerm_resource_group.this.name
  location                           = azurerm_resource_group.this.location
  sku_tier                           = var.static_web_app_sku_tier
  sku_size                           = var.static_web_app_sku_size
  preview_environments_enabled       = false
  public_network_access_enabled      = true
  configuration_file_changes_enabled = true

  tags = local.common_tags
}

resource "azurerm_dns_cname_record" "static_web_app" {
  count               = local.static_web_app_custom_domain_enabled ? 1 : 0
  name                = local.static_web_app_custom_domain_record_name
  zone_name           = data.azurerm_dns_zone.public[0].name
  resource_group_name = data.azurerm_dns_zone.public[0].resource_group_name
  ttl                 = 300
  record              = azurerm_static_web_app.this.default_host_name
}

resource "azurerm_static_web_app_custom_domain" "this" {
  count             = local.static_web_app_custom_domain_enabled ? 1 : 0
  static_web_app_id = azurerm_static_web_app.this.id
  domain_name       = var.static_web_app_custom_domain
  validation_type   = "cname-delegation"

  depends_on = [azurerm_dns_cname_record.static_web_app]
}
