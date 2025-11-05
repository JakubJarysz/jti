# 1. Create a resource group
resource "azurerm_resource_group" "main" {
  name     = "example-resources"
  location = "West Europe"
}

# 2. Create a virtual network within the resource group
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-${var.env}-net-1001"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = ["10.0.0.0/16"]
}

# 3. Create a subnet within the virtual network
resource "azurerm_subnet" "main" {
  name                 = "${var.prefix}-${var.env}-app-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "app-service-delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }

  service_endpoints = ["Microsoft.Storage", "Microsoft.ContainerRegistry"]
}

# 4. Create a subnet for PostgreSQL
resource "azurerm_subnet" "main" {
  name                 = "${var.prefix}-${var.env}-db-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]

  delegation {
    name = "postgres-delegation"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# Private DNS Zone dla PostgreSQL
resource "azurerm_private_dns_zone" "main" {
  name                = "${var.prefix}-${var.env}-postgres.private.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
}

# 5. Create a storage account within the resource group 
resource "azurerm_storage_account" "main" {
  name                     = "${var.prefix}-${var.env}-sto-1001"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}