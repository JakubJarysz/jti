#########################################################
# Select share resources
# Resource Group
data "azurerm_resource_group" "shr_rgp" {
  name     = "shr-${var.env}-rgp-1001"
  location = var.location
}
# Virtual Network
data "azurerm_virtual_network" "shr_vnet" {
  name                = "shr-${var.env}-net-1001"
  location            = azurerm_resource_group.shr_rgp.location
  resource_group_name = azurerm_resource_group.shr_rgp.name
}
# App Service Subnet
data "azurerm_subnet" "shr_appsubnet" {
  name                 = "shr-${var.env}-app-subnet"
  resource_group_name  = azurerm_resource_group.shr_rgp.name
  virtual_network_name = data.azurerm_virtual_network.shr_vnet.name
}

# PostgreSQL Subnet
data "azurerm_subnet" "shr_dbsubnet" {
  name                 = "shr-${var.env}-db-subnet"
  resource_group_name  = azurerm_resource_group.shr_rgp.name
  virtual_network_name = azurerm_virtual_network.shr_rgp.name
}
# PostgreSQL Private DNS Zone
data "azurerm_private_dns_zone" "shr_postgres_dns_zone" {
  name                = "shr-${var.env}-postgres.private.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.shr_rgp.name
}

#########################################################

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "${var.app_prefix}-${var.env}-postgres-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  resource_group_name   = azurerm_resource_group.shr_rgp.name
  virtual_network_id    = data.azurerm_virtual_network.shr_vnet.id
}

# Azure Container Registry
resource "azurerm_container_registry" "main" {
  name                = "${var.app_prefix}${var.env}acr1001"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  admin_enabled       = false

  network_rule_set {
    default_action = "Allow"
  }

  tags = var.tags
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "${var.app_prefix}-${var.env}-postgres-1001"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = "15"
  delegated_subnet_id    = azurerm_subnet.shr_dbsubnet.id
  private_dns_zone_id    = azurerm_private_dns_zone.shr_postgres_dns_zone.id
  administrator_login    = "psqladmin"
  administrator_password = "VeryDifficullPassword"

  storage_mb   = 32768
  storage_tier = "P4"

  sku_name = "B_Standard_B1ms"

  authentication {
    active_directory_auth_enabled = true
    password_auth_enabled         = true
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]

  tags = var.tags
}

# PostgreSQL Database
resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = "coolDb"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# PostgreSQL Firewall Rule - Allow Azure Services
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = "${var.app_prefix}-${var.env}-asp-1001"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "B1"

  tags = var.tags
}

# Linux Web App
resource "azurerm_linux_web_app" "main" {
  name                = "${var.app_prefix}-${var.env}-app-1001"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id

  identity {
    type         = "SystemAssigned"
  }

  site_config {
    always_on = false

    application_stack {
      docker_image_name   = "mcr.microsoft.com/appsvc/staticsite:latest"
      docker_registry_url = "https://${azurerm_container_registry.main.login_server}"
    }

    vnet_route_all_enabled = true
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "WEBSITES_PORT"                       = "8000"
    "DB_HOST"                             = azurerm_postgresql_flexible_server.main.fqdn
    "DB_NAME"                             = azurerm_postgresql_flexible_server_database.main.name
    "DB_USER"                             = azurerm_postgresql_flexible_server.main.administrator_login
    "DB_PASSWORD"                         = azurerm_postgresql_flexible_server.main.administrator_password
    "DB_PORT"                             = "5432"
    "DOCKER_REGISTRY_SERVER_URL"          = "https://${azurerm_container_registry.main.login_server}"
  }

  logs {
    http_logs {
      file_system {
        retention_in_days = 1
        retention_in_mb   = 35
      }
    }

    application_logs {
      file_system_level = "Information"
    }
  }

  tags = var.tags

  depends_on = [
    azurerm_role_assignment.acr_pull,
    azurerm_postgresql_flexible_server_active_directory_administrator.main
  ]
}

# VNet Integration dla Web App
resource "azurerm_app_service_virtual_network_swift_connection" "main" {
  app_service_id = azurerm_linux_web_app.main.id
  subnet_id      = azurerm_subnet.shr_appsubnet.id
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  count               = 1
  name                = "${var.app_prefix}-${var.env}-log-1001"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 1

  tags = var.tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  count               = 1
  name                = "${var.app_prefix}-${var.env}-ain-1001"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main[0].id
  application_type    = "web"

  tags = var.tags
}