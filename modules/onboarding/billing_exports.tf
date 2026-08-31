resource "time_static" "billing_exports_created" {
  count = var.enable_billing_exports ? 1 : 0

  rfc3339 = plantimestamp()

  lifecycle {
    ignore_changes = [rfc3339]
  }
}

resource "time_offset" "billing_backfill_period_start" {
  for_each = local.billing_backfill_month_keys

  base_rfc3339  = "${formatdate("YYYY-MM", time_static.billing_exports_created[0].rfc3339)}-01T00:00:00Z"
  offset_months = -tonumber(each.key)
}

resource "time_offset" "billing_backfill_period_end" {
  for_each = local.billing_backfill_month_keys

  base_rfc3339   = "${formatdate("YYYY-MM", time_static.billing_exports_created[0].rfc3339)}-01T00:00:00Z"
  offset_months  = -tonumber(each.key) + 1
  offset_seconds = -1
}

resource "azapi_resource_action" "billing_export_provider_registration" {
  for_each = local.billing_export_provider_registrations

  type        = "Microsoft.Resources/providers@2021-04-01"
  resource_id = "/subscriptions/${each.value.subscription_id}/providers/${each.value.namespace}"
  action      = "register"
  method      = "POST"
  body        = {}
}

resource "azapi_resource" "billing_export_resource_group" {
  count = var.enable_billing_exports && var.create_billing_export_storage_account ? 1 : 0

  type      = "Microsoft.Resources/resourceGroups@2021-04-01"
  name      = var.billing_export_resource_group_name
  parent_id = "/subscriptions/${local.billing_export_storage_subscription_id}"
  location  = var.billing_export_location
}

resource "azapi_resource" "billing_export_storage_account" {
  count = var.enable_billing_exports && var.create_billing_export_storage_account ? 1 : 0

  type      = "Microsoft.Storage/storageAccounts@2023-05-01"
  name      = local.billing_export_storage_account_requested_name
  parent_id = azapi_resource.billing_export_resource_group[0].id
  location  = var.billing_export_location
  tags      = local.billing_export_storage_tags

  body = {
    kind = "StorageV2"
    sku = {
      name = "Standard_LRS"
    }
    properties = {
      accessTier                   = "Hot"
      allowBlobPublicAccess        = false
      minimumTlsVersion            = "TLS1_2"
      publicNetworkAccess          = "Enabled"
      supportsHttpsTrafficOnly     = true
      defaultToOAuthAuthentication = false
      networkAcls = {
        bypass              = "AzureServices"
        defaultAction       = "Allow"
        ipRules             = []
        resourceAccessRules = []
        virtualNetworkRules = []
      }
    }
  }

  depends_on = [azapi_resource_action.billing_export_provider_registration]

  lifecycle {
    # Storage account names are immutable. Preserve an existing state value so upgrading
    # from the legacy random default cannot replace a data-bearing account. Tags are
    # creation-time metadata so Azure Policy and customer-owned tags are not removed.
    ignore_changes = [name, tags]
  }
}

resource "azapi_update_resource" "billing_export_storage_account_settings" {
  count = var.enable_billing_exports && var.manage_billing_export_storage_account_settings && (
    var.create_billing_export_storage_account || var.allow_existing_billing_export_storage_network_changes
  ) ? 1 : 0

  type        = "Microsoft.Storage/storageAccounts@2023-05-01"
  resource_id = local.billing_export_storage_account_id

  body = {
    properties = {
      allowBlobPublicAccess    = false
      minimumTlsVersion        = "TLS1_2"
      publicNetworkAccess      = "Enabled"
      supportsHttpsTrafficOnly = true
      networkAcls = {
        bypass              = "AzureServices"
        defaultAction       = "Allow"
        ipRules             = []
        resourceAccessRules = []
        virtualNetworkRules = []
      }
    }
  }

  depends_on = [
    azapi_resource.billing_export_storage_account,
    azapi_resource_action.billing_export_provider_registration
  ]
}

resource "azapi_resource" "billing_export_container" {
  count = var.enable_billing_exports ? 1 : 0

  type      = "Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01"
  name      = var.billing_export_container_name
  parent_id = "${local.billing_export_storage_account_id}/blobServices/default"

  body = {
    properties = {
      publicAccess = "None"
    }
  }

  depends_on = [
    azapi_resource.billing_export_storage_account,
    azapi_update_resource.billing_export_storage_account_settings
  ]
}

resource "azurerm_role_assignment" "billing_export_storage_reader" {
  count = var.enable_billing_exports ? 1 : 0

  scope                            = azapi_resource.billing_export_container[0].id
  role_definition_name             = "Storage Blob Data Reader"
  principal_id                     = azuread_service_principal.spotto.object_id
  skip_service_principal_aad_check = true

  depends_on = [time_sleep.sp_propagation]
}

resource "azurerm_role_assignment" "existing_billing_export_storage_reader" {
  for_each = local.existing_billing_export_container_scopes

  scope                            = each.value
  role_definition_name             = "Storage Blob Data Reader"
  principal_id                     = azuread_service_principal.spotto.object_id
  skip_service_principal_aad_check = true

  depends_on = [time_sleep.sp_propagation]
}

resource "azapi_resource" "billing_export_recurring" {
  for_each = local.billing_export_recurring_exports

  type      = "Microsoft.CostManagement/exports@2025-03-01"
  name      = each.value.recurring_export_name
  parent_id = "/subscriptions/${each.value.subscription_id}"

  body = {
    properties = {
      format                = "Csv"
      compressionMode       = "gzip"
      dataOverwriteBehavior = "OverwritePreviousReport"
      partitionData         = var.billing_export_partition_data
      definition = {
        type      = each.value.definition_type
        timeframe = "MonthToDate"
        dataSet = {
          granularity = "Daily"
        }
      }
      deliveryInfo = {
        destination = {
          type           = "AzureBlob"
          resourceId     = local.billing_export_storage_account_id
          container      = var.billing_export_container_name
          rootFolderPath = each.value.root_folder_path
        }
      }
      schedule = {
        status     = "Active"
        recurrence = "Daily"
        recurrencePeriod = {
          from = local.billing_export_schedule_from
          to   = local.billing_export_schedule_to
        }
      }
    }
  }

  schema_validation_enabled = false

  depends_on = [
    azapi_resource_action.billing_export_provider_registration,
    azurerm_role_assignment.billing_export_storage_reader
  ]
}

resource "azapi_resource_action" "billing_export_recurring_run" {
  for_each = var.enable_billing_exports && var.enable_billing_export_immediate_runs ? local.billing_export_recurring_exports : {}

  type        = "Microsoft.CostManagement/exports@2025-03-01"
  resource_id = azapi_resource.billing_export_recurring[each.key].id
  action      = "run"
  method      = "POST"
  body        = {}
}

resource "azapi_resource" "billing_export_management_group_recurring" {
  for_each = local.billing_export_management_group_recurring_exports

  type      = "Microsoft.CostManagement/exports@2025-03-01"
  name      = each.value.recurring_export_name
  parent_id = each.value.scope

  body = {
    properties = {
      format                = "Csv"
      compressionMode       = "None"
      dataOverwriteBehavior = "OverwritePreviousReport"
      partitionData         = var.billing_export_partition_data
      definition = {
        type      = each.value.dataset_type
        timeframe = "MonthToDate"
        dataSet = {
          granularity = "Daily"
        }
      }
      deliveryInfo = {
        destination = {
          type           = "AzureBlob"
          resourceId     = local.billing_export_storage_account_id
          container      = var.billing_export_container_name
          rootFolderPath = each.value.root_folder_path
        }
      }
      schedule = {
        status     = "Active"
        recurrence = "Daily"
        recurrencePeriod = {
          from = local.billing_export_schedule_from
          to   = local.billing_export_schedule_to
        }
      }
    }
  }

  schema_validation_enabled = false

  depends_on = [
    azapi_resource_action.billing_export_provider_registration,
    azurerm_role_assignment.billing_export_storage_reader
  ]
}

resource "azapi_resource_action" "billing_export_management_group_recurring_run" {
  for_each = var.enable_billing_exports && var.enable_billing_export_immediate_runs ? local.billing_export_management_group_recurring_exports : {}

  type        = "Microsoft.CostManagement/exports@2025-03-01"
  resource_id = azapi_resource.billing_export_management_group_recurring[each.key].id
  action      = "run"
  method      = "POST"
  body        = {}
}

resource "azapi_resource" "billing_export_backfill" {
  for_each = local.billing_export_backfill_exports

  type      = "Microsoft.CostManagement/exports@2025-03-01"
  name      = each.value.export_name
  parent_id = "/subscriptions/${each.value.subscription_id}"

  body = {
    properties = {
      format                = "Csv"
      compressionMode       = "gzip"
      dataOverwriteBehavior = "OverwritePreviousReport"
      partitionData         = var.billing_export_partition_data
      exportDescription     = var.enable_billing_export_backfill_runs ? "Spotto backfill queued ${each.value.period_name}" : "Spotto backfill pending ${each.value.period_name}"
      definition = {
        type      = each.value.definition_type
        timeframe = "Custom"
        timePeriod = {
          from = each.value.from
          to   = each.value.to
        }
        dataSet = {
          granularity = "Daily"
        }
      }
      deliveryInfo = {
        destination = {
          type           = "AzureBlob"
          resourceId     = local.billing_export_storage_account_id
          container      = var.billing_export_container_name
          rootFolderPath = each.value.root_folder_path
        }
      }
      schedule = {
        status = "Inactive"
      }
    }
  }

  schema_validation_enabled = false

  depends_on = [
    azapi_resource_action.billing_export_provider_registration,
    azurerm_role_assignment.billing_export_storage_reader
  ]
}

resource "azapi_resource_action" "billing_export_backfill_run" {
  for_each = var.enable_billing_exports && var.enable_billing_export_backfill && var.enable_billing_export_backfill_runs ? local.billing_export_backfill_exports : {}

  type        = "Microsoft.CostManagement/exports@2025-03-01"
  resource_id = azapi_resource.billing_export_backfill[each.key].id
  action      = "run"
  method      = "POST"

  body = {
    timePeriod = {
      from = each.value.from
      to   = each.value.to
    }
  }
}
