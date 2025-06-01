# Configure the Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "moodle" {
  name     = var.resource_group_name
  location = var.location
}

# Create MySQL Flexible Server
resource "azurerm_mysql_flexible_server" "moodle" {
  name                   = var.mysql_server_name
  resource_group_name    = azurerm_resource_group.moodle.name
  location              = azurerm_resource_group.moodle.location
  administrator_login    = var.mysql_admin_username
  administrator_password = var.mysql_admin_password
  backup_retention_days  = 7
  sku_name              = var.mysql_sku_name
  version               = "8.0"

  storage {
    auto_grow_enabled = true
    size_gb          = 20
  }

  tags = var.tags
}

# Create MySQL Database
resource "azurerm_mysql_flexible_database" "moodle" {
  name                = var.database_name
  resource_group_name = azurerm_resource_group.moodle.name
  server_name         = azurerm_mysql_flexible_server.moodle.name
  charset             = "utf8mb4"
  collation          = "utf8mb4_unicode_ci"
}

# Create MySQL Firewall Rule for Azure Services
resource "azurerm_mysql_flexible_server_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  resource_group_name = azurerm_resource_group.moodle.name
  server_name      = azurerm_mysql_flexible_server.moodle.name
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Create App Service Plan
resource "azurerm_service_plan" "moodle" {
  name                = var.app_service_plan_name
  resource_group_name = azurerm_resource_group.moodle.name
  location           = azurerm_resource_group.moodle.location
  os_type            = "Linux"
  sku_name           = var.app_service_sku

  tags = var.tags
}

# Create App Service
resource "azurerm_linux_web_app" "moodle" {
  name                = var.app_service_name
  resource_group_name = azurerm_resource_group.moodle.name
  location           = azurerm_service_plan.moodle.location
  service_plan_id    = azurerm_service_plan.moodle.id

  site_config {
    application_stack {
      php_version = "8.1"
    }
    
    always_on = true
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "PHP_INI_SCAN_DIR"                   = "/usr/local/etc/php/conf.d:/home/site/ini"
  }

  connection_string {
    name  = "DefaultConnection"
    type  = "MySql"
    value = "Server=${azurerm_mysql_flexible_server.moodle.fqdn};Database=${azurerm_mysql_flexible_database.moodle.name};Uid=${var.mysql_admin_username};Pwd=${var.mysql_admin_password};"
  }

  tags = var.tags
}

# Output values
output "resource_group_name" {
  value = azurerm_resource_group.moodle.name
}

output "mysql_server_fqdn" {
  value = azurerm_mysql_flexible_server.moodle.fqdn
}

output "app_service_url" {
  value = "https://${azurerm_linux_web_app.moodle.default_hostname}"
}

output "app_service_name" {
  value = azurerm_linux_web_app.moodle.name
}
