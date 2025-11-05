variable "env" {
  description = "Environment (dev, prod, etc.)"
  type        = string
  default     = "dev"
}

variable "resource_group_name" {
  description = "Nazwa Resource Group"
  type        = string
  default     = "shr-dev-rgp-1001"
}

variable "location" {
  description = "Lokalizacja Azure"
  type        = string
  default     = "westeurope"
}

variable "prefix" {
  description = "Prefix dla nazw zasobów"
  type        = string
  default     = "shr"
}

variable "tags" {
  description = "Tagi do przypisania do zasobów"
  type        = map(string)
  default = {
    Environment = var.env
    ManagedBy   = "Terraform"
    Project     = "SHR"
  }
}