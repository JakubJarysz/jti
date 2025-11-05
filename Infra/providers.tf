terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=4.51.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.47.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azuread" {
  # Configuration options
}

# Data source for current Azure subscription
data "azurerm_subscription" "current" {}

# Data source for current Azure client configuration
data "azurerm_client_config" "current" {}