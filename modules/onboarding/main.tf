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
  tenant_id                    = coalesce(var.tenant_id, data.azurerm_client_config.current.tenant_id)
  tenant_root_scope            = "/"
  reservations_scope           = "/providers/Microsoft.Capacity"
  savings_plan_scope           = "/providers/Microsoft.BillingBenefits"
  management_group_id          = coalesce(var.root_management_group_id, local.tenant_id)
  management_group_scope       = "/providers/Microsoft.Management/managementGroups/${local.management_group_id}"
  all_subscription_ids         = var.assign_reader_to_all_subscriptions ? [for sub in data.azurerm_subscriptions.current[0].subscriptions : sub.subscription_id] : []
  effective_subscription_ids   = var.assign_reader_to_all_subscriptions ? local.all_subscription_ids : var.subscription_ids
  subscription_scopes          = [for id in local.effective_subscription_ids : "/subscriptions/${id}"]
  enable_log_analytics_reader  = var.enable_log_analytics_data_reader != null ? var.enable_log_analytics_data_reader : var.enable_log_analytics_reader
  graph_app_role_id            = var.enable_graph_permission ? one([for role in data.azuread_service_principal.msgraph[0].app_roles : role.id if role.value == "Application.Read.All" && contains(role.allowed_member_types, "Application")]) : null
  custom_role_scope            = local.subscription_scopes[0]
  secret_end_date              = var.client_secret_end_date != null ? var.client_secret_end_date : (var.create_client_secret ? timeadd(time_static.secret_created[0].rfc3339, "8760h") : null)
  root_reader_assignment_name  = uuidv5("url", "${local.tenant_root_scope}|${data.azurerm_role_definition.reader.id}|${azuread_service_principal.spotto.object_id}")
  reservations_assignment_name = uuidv5("url", "${local.reservations_scope}|${data.azurerm_role_definition.reservations_reader.id}|${azuread_service_principal.spotto.object_id}")
  savings_plan_assignment_name = uuidv5("url", "${local.savings_plan_scope}|${data.azurerm_role_definition.savings_plan_reader.id}|${azuread_service_principal.spotto.object_id}")
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
      roleDefinitionId = data.azurerm_role_definition.reader.id
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
      roleDefinitionId = data.azurerm_role_definition.reservations_reader.id
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
      roleDefinitionId = data.azurerm_role_definition.savings_plan_reader.id
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
