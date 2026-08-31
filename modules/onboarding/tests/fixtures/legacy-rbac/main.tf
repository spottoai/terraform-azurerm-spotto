terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    azapi = {
      source = "Azure/azapi"
    }
    azuread = {
      source = "hashicorp/azuread"
    }
    random = {
      source = "hashicorp/random"
    }
    time = {
      source = "hashicorp/time"
    }
  }
}

variable "management_group_scope" {
  type = string
}

variable "principal_id" {
  type = string
}

resource "azurerm_role_assignment" "log_analytics_reader_management_group" {
  count = 1

  scope                            = var.management_group_scope
  role_definition_name             = "Log Analytics Reader"
  principal_id                     = var.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "reader_management_group" {
  count = 1

  scope                            = var.management_group_scope
  role_definition_name             = "Reader"
  principal_id                     = var.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "management_group_reader" {
  count = 1

  scope                            = var.management_group_scope
  role_definition_name             = "Management Group Reader"
  principal_id                     = var.principal_id
  skip_service_principal_aad_check = true
}

output "log_analytics_reader_id" {
  value = azurerm_role_assignment.log_analytics_reader_management_group[0].id
}

output "reader_id" {
  value = azurerm_role_assignment.reader_management_group[0].id
}

output "management_group_reader_id" {
  value = azurerm_role_assignment.management_group_reader[0].id
}
