output "resource_group_name" {
  description = "Environment resource group name."
  value       = azurerm_resource_group.this.name
}

output "static_web_app_name" {
  description = "Azure Static Web App name."
  value       = azurerm_static_web_app.this.name
}

output "static_web_app_default_host_name" {
  description = "Default host name for the Static Web App."
  value       = azurerm_static_web_app.this.default_host_name
}

output "static_web_app_custom_domain" {
  description = "Configured custom domain for the Static Web App."
  value       = local.static_web_app_custom_domain_enabled ? var.static_web_app_custom_domain : null
}
