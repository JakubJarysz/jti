# Create a resource group
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-${var.env}-rgp-1001"
  location = "West Europe"
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-${var.env}-net-1001"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = ["10.0.0.0/16"]
}

# Create a subnet within the virtual network
resource "azurerm_subnet" "main_app" {
  name                 = "${var.prefix}-${var.env}-app-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create a subnet for PostgreSQL
resource "azurerm_subnet" "main_db" {
  name                 = "${var.prefix}-${var.env}-db-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
  private_endpoint_network_policies = "Enabled"
  service_endpoints = ["Microsoft.Sql"]
}

# Private DNS Zone dla PostgreSQL
resource "azurerm_private_dns_zone" "main" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-${var.env}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "PostgreSQL"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "0.0.0.0/0"  
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "HTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "0.0.0.0/0"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.main_db.id
  network_security_group_id = azurerm_network_security_group.main.id
}


resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "${var.prefix}-${var.env}-postgres-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.main.name
  resource_group_name   = azurerm_resource_group.main.name
  virtual_network_id    = azurerm_virtual_network.main.id
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "${var.prefix}-${var.env}-postgres-1002"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = "16"
  sku_name               = "B_Standard_B1ms" 
  zone                   = 3 
  administrator_login    = "psqladmin"
  administrator_password = "VeryDifficullPassword"
  public_network_access_enabled = false
  storage_mb   = 32768
  storage_tier = "P4"
  
  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
  tags = var.tags
}

//PostgresSQL Private Endpoint
resource "azurerm_private_endpoint" "main" {
  name                = "${var.prefix}-${var.env}-pep-1002-postgresql"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.main_db.id
  private_service_connection {
    name                           = "${var.prefix}-${var.env}-pep-1002-postgresql"
    private_connection_resource_id = azurerm_postgresql_flexible_server.main.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = azurerm_postgresql_flexible_server.main.name
    private_dns_zone_ids = [azurerm_private_dns_zone.main.id]
  }
  depends_on = [azurerm_postgresql_flexible_server.main]
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

# Azure Container Registry
resource "azurerm_container_registry" "main" {
  name                = "${var.prefix}${var.env}acr1001"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Premium"
  admin_enabled       = true
  tags = var.tags
}

# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = "${var.prefix}-${var.env}-asp-1001"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "F1"
  tags = var.tags
}

# Linux Web App
resource "azurerm_linux_web_app" "main" {
  name                = "${var.prefix}-${var.env}-app-1001"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id
  identity {
    type         = "SystemAssigned"
  }
  site_config {
    always_on = false
    application_stack {
      docker_image_name = "${azurerm_container_registry.main.login_server}/testapp:latest"
    }
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "WEBSITES_PORT"                       = "8000"
    "DB_HOST"                             = azurerm_postgresql_flexible_server.main.fqdn
    "DB_NAME"                             = azurerm_postgresql_flexible_server_database.main.name
    "DB_USER"                             = azurerm_postgresql_flexible_server.main.administrator_login
    "DB_PASSWORD"                         = azurerm_postgresql_flexible_server.main.administrator_password
    "DB_PORT"                             = "5432"
  }
  logs {
    http_logs {
      file_system {
        retention_in_days = 30
        retention_in_mb   = 35
      }
    }
    application_logs {
      file_system_level = "Information"
    }
  }
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  count               = 1
  name                = "${var.prefix}-${var.env}-log-1001"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags = var.tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  count               = 1
  name                = "${var.prefix}-${var.env}-ain-1001"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main[0].id
  retention_in_days = 30
  application_type    = "web"
  tags = var.tags
}