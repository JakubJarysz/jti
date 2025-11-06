terraform {
  backend "azurerm" {
    resource_group_name  = "jti-dev-rgp-1001"
    storage_account_name = "jtidevsto1001"
    container_name       = "tfstate"
    key                  = "jit.terraform.tfstate"
  }
}

# Aby utworzyć backend storage account, uruchom:
# 
# RESOURCE_GROUP_NAME="terraform-state-rg"
# STORAGE_ACCOUNT_NAME="tfstate$(openssl rand -hex 4)"
# CONTAINER_NAME="tfstate"
# LOCATION="westeurope"
# 
# # Utwórz resource group
# az group create --name $RESOURCE_GROUP_NAME --location $LOCATION
# 
# # Utwórz storage account
# az storage account create \
#   --resource-group $RESOURCE_GROUP_NAME \
#   --name $STORAGE_ACCOUNT_NAME \
#   --sku Standard_LRS \
#   --encryption-services blob \
#   --location $LOCATION
# 
# # Utwórz container
# az storage container create \
#   --name $CONTAINER_NAME \
#   --account-name $STORAGE_ACCOUNT_NAME
# 
# # Włącz versioning
# az storage account blob-service-properties update \
#   --account-name $STORAGE_ACCOUNT_NAME \
#   --resource-group $RESOURCE_GROUP_NAME \
#   --enable-versioning true