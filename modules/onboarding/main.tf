data "azurerm_client_config" "current" {}

data "azurerm_subscriptions" "current" {
  count = var.assign_reader_to_all_subscriptions ? 1 : 0
}

data "azurerm_role_definition" "reader" {
  name = "Reader"
}

data "azurerm_role_definition" "reservations_reader" {
  name = "Reservations Reader"
}

data "azurerm_role_definition" "savings_plan_reader" {
  name = "Savings plan Reader"
}

data "azuread_service_principal" "msgraph" {
  count     = var.enable_graph_permission ? 1 : 0
  client_id = "00000003-0000-0000-c000-000000000000"
}

locals {
  tenant_id                              = coalesce(var.tenant_id, data.azurerm_client_config.current.tenant_id)
  tenant_root_scope                      = "/"
  reservations_scope                     = "/providers/Microsoft.Capacity"
  savings_plan_scope                     = "/providers/Microsoft.BillingBenefits"
  management_group_id                    = coalesce(var.root_management_group_id, local.tenant_id)
  management_group_scope                 = "/providers/Microsoft.Management/managementGroups/${local.management_group_id}"
  all_subscription_ids                   = var.assign_reader_to_all_subscriptions ? [for sub in data.azurerm_subscriptions.current[0].subscriptions : sub.subscription_id] : []
  effective_subscription_ids             = var.assign_reader_to_all_subscriptions ? local.all_subscription_ids : var.subscription_ids
  subscription_scopes                    = [for id in local.effective_subscription_ids : "/subscriptions/${id}"]
  enable_log_analytics_reader            = var.enable_log_analytics_data_reader != null ? var.enable_log_analytics_data_reader : var.enable_log_analytics_reader
  graph_app_role_id                      = var.enable_graph_permission ? one([for role in data.azuread_service_principal.msgraph[0].app_roles : role.id if role.value == "Application.Read.All" && contains(role.allowed_member_types, "Application")]) : null
  custom_role_scope                      = local.subscription_scopes[0]
  secret_end_date                        = var.client_secret_end_date != null ? var.client_secret_end_date : (var.create_client_secret ? timeadd(time_static.secret_created[0].rfc3339, "8760h") : null)
  reader_role_definition_id              = "/providers/Microsoft.Authorization/roleDefinitions/${data.azurerm_role_definition.reader.role_definition_id}"
  reservations_reader_role_definition_id = "/providers/Microsoft.Authorization/roleDefinitions/${data.azurerm_role_definition.reservations_reader.role_definition_id}"
  savings_plan_reader_role_definition_id = "/providers/Microsoft.Authorization/roleDefinitions/${data.azurerm_role_definition.savings_plan_reader.role_definition_id}"
  root_reader_assignment_name            = uuidv5("url", "${local.tenant_root_scope}|${local.reader_role_definition_id}|${azuread_service_principal.spotto.object_id}")
  reservations_assignment_name           = uuidv5("url", "${local.reservations_scope}|${local.reservations_reader_role_definition_id}|${azuread_service_principal.spotto.object_id}")
  savings_plan_assignment_name           = uuidv5("url", "${local.savings_plan_scope}|${local.savings_plan_reader_role_definition_id}|${azuread_service_principal.spotto.object_id}")
  billing_export_dataset_config = {
    ActualCost = {
      definition_type       = var.billing_export_actual_cost_definition_type
      dataset_folder        = "actual"
      recurring_export_name = "spotto-actual-daily"
    }
    AmortizedCost = {
      definition_type       = "AmortizedCost"
      dataset_folder        = "amortized"
      recurring_export_name = "spotto-amortized-daily"
    }
  }
  billing_export_storage_account_id = var.enable_billing_exports ? (
    var.create_billing_export_storage_account ? azapi_resource.billing_export_storage_account[0].id : var.billing_export_storage_account_id
  ) : null
  existing_billing_export_storage_subscription_id = var.billing_export_storage_account_id != null ? split("/", var.billing_export_storage_account_id)[2] : null
  billing_export_storage_subscription_id = coalesce(
    var.billing_export_storage_subscription_id,
    var.create_billing_export_storage_account ? try(local.effective_subscription_ids[0], data.azurerm_client_config.current.subscription_id) : local.existing_billing_export_storage_subscription_id,
    data.azurerm_client_config.current.subscription_id
  )
  billing_export_cost_management_provider_registrations = var.enable_billing_exports && var.enable_billing_export_resource_provider_registration ? {
    for subscription_id in toset(local.effective_subscription_ids) :
    "${subscription_id}|Microsoft.CostManagement" => {
      subscription_id = subscription_id
      namespace       = "Microsoft.CostManagement"
    }
  } : {}
  billing_export_storage_provider_registrations = var.enable_billing_exports && var.enable_billing_export_resource_provider_registration ? merge(
    var.create_billing_export_storage_account ? {
      "${local.billing_export_storage_subscription_id}|Microsoft.Storage" = {
        subscription_id = local.billing_export_storage_subscription_id
        namespace       = "Microsoft.Storage"
      }
    } : {},
    {
      "${local.billing_export_storage_subscription_id}|Microsoft.CostManagement" = {
        subscription_id = local.billing_export_storage_subscription_id
        namespace       = "Microsoft.CostManagement"
      }
      "${local.billing_export_storage_subscription_id}|Microsoft.CostManagementExports" = {
        subscription_id = local.billing_export_storage_subscription_id
        namespace       = "Microsoft.CostManagementExports"
      }
    }
  ) : {}
  billing_export_provider_registrations = merge(
    local.billing_export_cost_management_provider_registrations,
    local.billing_export_storage_provider_registrations
  )
  billing_export_schedule_from = var.enable_billing_exports ? "${formatdate("YYYY-MM-DD", timeadd(time_static.billing_exports_created[0].rfc3339, "24h"))}T00:00:00Z" : null
  billing_export_schedule_to   = var.enable_billing_exports ? "${formatdate("YYYY-MM-DD", timeadd(time_static.billing_exports_created[0].rfc3339, "87600h"))}T00:00:00Z" : null
  billing_export_recurring_exports = var.enable_billing_exports ? {
    for pair in setproduct(toset(local.effective_subscription_ids), toset(var.billing_export_dataset_types)) :
    "${pair[0]}|${pair[1]}" => {
      subscription_id       = pair[0]
      dataset_type          = pair[1]
      definition_type       = local.billing_export_dataset_config[pair[1]].definition_type
      dataset_folder        = local.billing_export_dataset_config[pair[1]].dataset_folder
      recurring_export_name = local.billing_export_dataset_config[pair[1]].recurring_export_name
      root_folder_path      = "${var.billing_export_root_path}/${pair[0]}/${local.billing_export_dataset_config[pair[1]].dataset_folder}/recurring"
    }
  } : {}
  billing_backfill_periods = var.enable_billing_exports && var.enable_billing_export_backfill ? [
    for index in range(var.billing_export_backfill_month_count) : {
      name = formatdate("YYYYMM", time_offset.billing_backfill_period_start[index].rfc3339)
      from = time_offset.billing_backfill_period_start[index].rfc3339
      to   = time_offset.billing_backfill_period_end[index].rfc3339
    }
  ] : []
  billing_export_backfill_exports = var.enable_billing_exports && var.enable_billing_export_backfill ? {
    for pair in setproduct(values(local.billing_export_recurring_exports), local.billing_backfill_periods) :
    "${pair[0].subscription_id}|${pair[0].dataset_type}|${pair[1].name}" => {
      subscription_id  = pair[0].subscription_id
      dataset_type     = pair[0].dataset_type
      definition_type  = pair[0].definition_type
      dataset_folder   = pair[0].dataset_folder
      period_name      = pair[1].name
      from             = pair[1].from
      to               = pair[1].to
      export_name      = "spotto-${pair[0].dataset_folder}-backfill-${pair[1].name}"
      root_folder_path = "${var.billing_export_root_path}/${pair[0].subscription_id}/${pair[0].dataset_folder}/backfill/${pair[1].name}"
    }
  } : {}
  custom_role_actions = [
    "Microsoft.Advisor/recommendations/write",
    "Microsoft.Advisor/recommendations/suppressions/write",
    "Microsoft.Advisor/recommendations/suppressions/delete",
    "Microsoft.Storage/storageAccounts/inventoryPolicies/write",
    "Microsoft.Storage/storageAccounts/inventoryPolicies/read"
  ]
}

resource "azuread_application" "spotto" {
  display_name = var.app_name

  dynamic "required_resource_access" {
    for_each = var.enable_graph_permission ? [1] : []

    content {
      resource_app_id = "00000003-0000-0000-c000-000000000000"

      resource_access {
        id   = local.graph_app_role_id
        type = "Role"
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.assign_reader_to_all_subscriptions || length(var.subscription_ids) > 0
      error_message = "Provide subscription_ids or set assign_reader_to_all_subscriptions to true."
    }
    precondition {
      condition     = !var.enable_billing_exports || var.create_billing_export_storage_account || var.billing_export_storage_account_id != null
      error_message = "When enable_billing_exports is true and create_billing_export_storage_account is false, provide billing_export_storage_account_id."
    }
    precondition {
      condition     = !var.enable_billing_exports || length(local.effective_subscription_ids) > 0
      error_message = "When enable_billing_exports is true, at least one effective subscription must be resolved for Cost Management exports."
    }
  }
}

resource "azuread_service_principal" "spotto" {
  client_id = azuread_application.spotto.client_id
}

resource "time_static" "secret_created" {
  count = var.create_client_secret && var.client_secret_end_date == null ? 1 : 0
}

resource "azuread_application_password" "spotto" {
  count                 = var.create_client_secret ? 1 : 0
  application_object_id = azuread_application.spotto.object_id
  display_name          = "spotto-onboarding"
  end_date              = local.secret_end_date
}

resource "azuread_app_role_assignment" "graph_app_read_all" {
  count = var.enable_graph_permission ? 1 : 0

  app_role_id         = local.graph_app_role_id
  principal_object_id = azuread_service_principal.spotto.object_id
  resource_object_id  = data.azuread_service_principal.msgraph[0].object_id

  depends_on = [time_sleep.sp_propagation]
}

resource "time_sleep" "sp_propagation" {
  create_duration = var.service_principal_propagation_delay

  depends_on = [azuread_service_principal.spotto]
}

resource "time_static" "billing_exports_created" {
  count = var.enable_billing_exports ? 1 : 0
}

resource "time_offset" "billing_backfill_period_start" {
  count = var.enable_billing_exports && var.enable_billing_export_backfill ? var.billing_export_backfill_month_count : 0

  base_rfc3339  = "${formatdate("YYYY-MM", time_static.billing_exports_created[0].rfc3339)}-01T00:00:00Z"
  offset_months = -var.billing_export_backfill_month_count + count.index
}

resource "time_offset" "billing_backfill_period_end" {
  count = var.enable_billing_exports && var.enable_billing_export_backfill ? var.billing_export_backfill_month_count : 0

  base_rfc3339   = "${formatdate("YYYY-MM", time_static.billing_exports_created[0].rfc3339)}-01T00:00:00Z"
  offset_months  = -var.billing_export_backfill_month_count + count.index + 1
  offset_seconds = -1
}

resource "random_string" "billing_export_storage_account" {
  count = var.enable_billing_exports && var.create_billing_export_storage_account && var.billing_export_storage_account_name == null ? 1 : 0

  length  = 13
  lower   = true
  numeric = true
  special = false
  upper   = false
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
  name      = var.billing_export_storage_account_name != null ? var.billing_export_storage_account_name : "spotto${random_string.billing_export_storage_account[0].result}"
  parent_id = azapi_resource.billing_export_resource_group[0].id
  location  = var.billing_export_location

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
}

resource "azapi_update_resource" "billing_export_storage_account_settings" {
  count = var.enable_billing_exports && var.manage_billing_export_storage_account_settings ? 1 : 0

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

resource "azurerm_role_assignment" "reader" {
  for_each                         = var.assign_reader_to_all_subscriptions ? toset([]) : toset(local.subscription_scopes)
  scope                            = each.value
  role_definition_name             = "Reader"
  principal_id                     = azuread_service_principal.spotto.object_id
  skip_service_principal_aad_check = true

  depends_on = [time_sleep.sp_propagation]
}

resource "azapi_resource" "reader_root" {
  count     = var.assign_reader_to_all_subscriptions ? 1 : 0
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = local.root_reader_assignment_name
  parent_id = local.tenant_root_scope

  body = {
    properties = {
      principalId      = azuread_service_principal.spotto.object_id
      principalType    = "ServicePrincipal"
      roleDefinitionId = local.reader_role_definition_id
    }
  }

  depends_on = [time_sleep.sp_propagation]
}

resource "azurerm_role_assignment" "monitoring_reader" {
  for_each                         = var.enable_monitoring_reader ? toset(local.subscription_scopes) : toset([])
  scope                            = each.value
  role_definition_name             = "Monitoring Reader"
  principal_id                     = azuread_service_principal.spotto.object_id
  skip_service_principal_aad_check = true

  depends_on = [time_sleep.sp_propagation]
}

resource "azurerm_role_assignment" "log_analytics_reader_subscription" {
  for_each                         = local.enable_log_analytics_reader && !var.assign_reader_to_all_subscriptions ? toset(local.subscription_scopes) : toset([])
  scope                            = each.value
  role_definition_name             = "Log Analytics Reader"
  principal_id                     = azuread_service_principal.spotto.object_id
  skip_service_principal_aad_check = true

  depends_on = [time_sleep.sp_propagation]
}

resource "azurerm_role_assignment" "log_analytics_reader_management_group" {
  count                            = local.enable_log_analytics_reader && var.assign_reader_to_all_subscriptions ? 1 : 0
  scope                            = local.management_group_scope
  role_definition_name             = "Log Analytics Reader"
  principal_id                     = azuread_service_principal.spotto.object_id
  skip_service_principal_aad_check = true

  depends_on = [time_sleep.sp_propagation]
}

resource "azurerm_role_assignment" "reader_management_group" {
  count                            = var.enable_management_group_reader ? 1 : 0
  scope                            = local.management_group_scope
  role_definition_name             = "Reader"
  principal_id                     = azuread_service_principal.spotto.object_id
  skip_service_principal_aad_check = true

  depends_on = [time_sleep.sp_propagation]
}

resource "azurerm_role_assignment" "management_group_reader" {
  count                            = var.enable_management_group_reader ? 1 : 0
  scope                            = local.management_group_scope
  role_definition_name             = "Management Group Reader"
  principal_id                     = azuread_service_principal.spotto.object_id
  skip_service_principal_aad_check = true

  depends_on = [time_sleep.sp_propagation]
}

resource "azapi_resource" "reservations_reader" {
  count     = var.enable_reservations_reader ? 1 : 0
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = local.reservations_assignment_name
  parent_id = local.reservations_scope

  body = {
    properties = {
      principalId      = azuread_service_principal.spotto.object_id
      principalType    = "ServicePrincipal"
      roleDefinitionId = local.reservations_reader_role_definition_id
    }
  }

  depends_on = [time_sleep.sp_propagation]
}

resource "azapi_resource" "savings_plan_reader" {
  count     = var.enable_savings_plan_reader ? 1 : 0
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = local.savings_plan_assignment_name
  parent_id = local.savings_plan_scope

  body = {
    properties = {
      principalId      = azuread_service_principal.spotto.object_id
      principalType    = "ServicePrincipal"
      roleDefinitionId = local.savings_plan_reader_role_definition_id
    }
  }

  depends_on = [time_sleep.sp_propagation]
}

resource "random_uuid" "spotto_role" {
  count = var.grant_optional_write_permissions ? 1 : 0
}

resource "azurerm_role_definition" "spotto_write" {
  count              = var.grant_optional_write_permissions ? 1 : 0
  role_definition_id = random_uuid.spotto_role[0].result
  name               = var.custom_role_name
  scope              = local.custom_role_scope
  description        = "Custom role for Spotto to manage Azure Advisor recommendations and Storage inventory"

  permissions {
    actions = local.custom_role_actions
  }

  assignable_scopes = local.subscription_scopes
}

resource "time_sleep" "role_propagation" {
  count           = var.grant_optional_write_permissions ? 1 : 0
  create_duration = var.custom_role_propagation_delay

  depends_on = [azurerm_role_definition.spotto_write]
}

resource "azurerm_role_assignment" "spotto_write" {
  for_each                         = var.grant_optional_write_permissions ? toset(local.subscription_scopes) : toset([])
  scope                            = each.value
  role_definition_id               = azurerm_role_definition.spotto_write[0].role_definition_resource_id
  principal_id                     = azuread_service_principal.spotto.object_id
  skip_service_principal_aad_check = true

  depends_on = [time_sleep.role_propagation, time_sleep.sp_propagation]
}
