terraform {
  required_version = ">= 1.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0, < 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.40, < 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5, < 4.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9, < 1.0"
    }
  }
}
