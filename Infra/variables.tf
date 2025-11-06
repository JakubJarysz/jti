variable "env" {
  description = "Environment name (dev, prod, etc.)"
  type        = string
  default     = "dev"

  # Optional: Add validation for allowed environments
  validation {
    condition     = contains(["dev", "test", "prod"], var.env)
    error_message = "Environment must be one of: dev, test, prod"
  }
}

variable "resource_group_name" {
  description = "Name of the application Resource Group"
  type        = string
  default     = "jti-dev-rgp-1001"
}

variable "location" {
  description = "Azure region for resource deployment"
  type        = string
  default     = "westeurope"
}

variable "prefix" {
  description = "Prefix for resource naming"
  type        = string
  default     = "jti"
}

variable "tags" {
  description = "Tags to assign to resources"
  type        = map(string)
  default = {
    Environment = "dev"
    ManagedBy   = "Terraform"
    Project     = "JTI"
  }
}