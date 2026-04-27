locals {
  dns_zone_enabled                         = var.dns_zone_name != "" && var.dns_zone_resource_group_name != ""
  static_web_app_custom_domain_enabled     = local.dns_zone_enabled && var.static_web_app_custom_domain != ""
  static_web_app_custom_domain_record_name = local.static_web_app_custom_domain_enabled ? trimsuffix(var.static_web_app_custom_domain, ".${var.dns_zone_name}") : ""

  common_tags = merge(
    {
      application = "autopack"
      environment = var.environment
      managed_by  = "terraform"
      workload    = "website"
    },
    var.tags,
  )
}
