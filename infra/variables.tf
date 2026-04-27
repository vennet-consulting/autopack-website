variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "location" {
  description = "Azure region for the environment resources."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name for the environment resources."
  type        = string
}

variable "static_web_app_name" {
  description = "Azure Static Web App name."
  type        = string
}

variable "static_web_app_sku_tier" {
  description = "Static Web App SKU tier."
  type        = string
  default     = "Free"
}

variable "static_web_app_sku_size" {
  description = "Static Web App SKU size."
  type        = string
  default     = "Free"
}

variable "dns_zone_name" {
  description = "Public Azure DNS zone name used for the custom domain CNAME record."
  type        = string
  default     = ""
}

variable "dns_zone_resource_group_name" {
  description = "Resource group that contains the public Azure DNS zone."
  type        = string
  default     = ""
}

variable "static_web_app_custom_domain" {
  description = "Optional custom hostname for the Static Web App."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default     = {}
}
