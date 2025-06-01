variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-moodle-terraform"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "mysql_server_name" {
  description = "Name of the MySQL server"
  type        = string
  default     = "moodle-mysql-server"
}

variable "mysql_admin_username" {
  description = "MySQL administrator username"
  type        = string
  default     = "moodleadmin"
}

variable "mysql_admin_password" {
  description = "MySQL administrator password"
  type        = string
  sensitive   = true
}

variable "mysql_sku_name" {
  description = "MySQL server SKU"
  type        = string
  default     = "B_Standard_B1s"
}

variable "database_name" {
  description = "Name of the Moodle database"
  type        = string
  default     = "moodle"
}

variable "app_service_plan_name" {
  description = "Name of the App Service Plan"
  type        = string
  default     = "moodle-asp"
}

variable "app_service_sku" {
  description = "App Service Plan SKU"
  type        = string
  default     = "B1"
}

variable "app_service_name" {
  description = "Name of the App Service"
  type        = string
  default     = "moodle-webapp"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "Development"
    Project     = "Moodle"
    ManagedBy   = "Terraform"
  }
}
