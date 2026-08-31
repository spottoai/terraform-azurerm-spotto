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

resource "azurerm_role_assignment" "security_reader" {
  for_each                         = var.enable_security_reader ? toset(local.subscription_scopes) : toset([])
  scope                            = each.value
  role_definition_name             = "Security Reader"
  principal_id                     = azuread_service_principal.spotto.object_id
  skip_service_principal_aad_check = true

  depends_on = [time_sleep.sp_propagation]
}

resource "azurerm_role_assignment" "monitoring_reader_management_group" {
  for_each = var.enable_management_group_monitoring_reader ? local.extended_management_group_scopes : toset([])

  scope                            = each.value
  role_definition_name             = "Monitoring Reader"
  principal_id                     = azuread_service_principal.spotto.object_id
  skip_service_principal_aad_check = true

  depends_on = [time_sleep.sp_propagation]
}

resource "azurerm_role_assignment" "key_vault_reader_subscription" {
  for_each = var.enable_key_vault_reader && (!var.assign_reader_to_all_subscriptions || length(var.management_group_ids) > 0) ? toset(local.subscription_scopes) : toset([])

  scope                            = each.value
  role_definition_name             = "Key Vault Reader"
  principal_id                     = azuread_service_principal.spotto.object_id
  skip_service_principal_aad_check = true

  depends_on = [time_sleep.sp_propagation]
}

resource "azurerm_role_assignment" "key_vault_reader_management_group" {
  for_each = var.enable_key_vault_reader ? local.extended_management_group_scopes : toset([])

  scope                            = each.value
  role_definition_name             = "Key Vault Reader"
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
  for_each = local.enable_log_analytics_reader ? local.extended_management_group_scope_map : {}

  scope                            = each.value
  role_definition_name             = "Log Analytics Reader"
  principal_id                     = azuread_service_principal.spotto.object_id
  skip_service_principal_aad_check = true

  depends_on = [time_sleep.sp_propagation]
}

resource "azurerm_role_assignment" "reader_management_group" {
  for_each = var.enable_management_group_reader ? local.extended_management_group_scope_map : {}

  scope                            = each.value
  role_definition_name             = "Reader"
  principal_id                     = azuread_service_principal.spotto.object_id
  skip_service_principal_aad_check = true

  depends_on = [time_sleep.sp_propagation]
}

resource "azurerm_role_assignment" "management_group_reader" {
  for_each = var.enable_management_group_reader ? local.management_group_scope_map : {}

  scope                            = each.value
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

resource "azapi_resource" "reservations_contributor" {
  count     = var.enable_reservations_contributor ? 1 : 0
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = local.reservations_contributor_assignment_name
  parent_id = local.reservations_scope

  body = {
    properties = {
      principalId      = azuread_service_principal.spotto.object_id
      principalType    = "ServicePrincipal"
      roleDefinitionId = local.reservations_contributor_role_definition_id
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
  count = local.optional_write_role_enabled ? 1 : 0
}

resource "azurerm_role_definition" "spotto_write" {
  count              = local.optional_write_role_enabled ? 1 : 0
  role_definition_id = random_uuid.spotto_role[0].result
  name               = var.custom_role_name
  scope              = local.custom_role_scope
  description        = "Custom role for explicitly selected Spotto subscription write capabilities"

  permissions {
    actions = local.custom_role_actions
  }

  assignable_scopes = local.subscription_scopes
}

resource "time_sleep" "role_propagation" {
  count           = local.optional_write_role_enabled ? 1 : 0
  create_duration = var.custom_role_propagation_delay

  depends_on = [azurerm_role_definition.spotto_write]
}

resource "azurerm_role_assignment" "spotto_write" {
  for_each                         = local.optional_write_role_enabled ? toset(local.subscription_scopes) : toset([])
  scope                            = each.value
  role_definition_id               = azurerm_role_definition.spotto_write[0].role_definition_resource_id
  principal_id                     = azuread_service_principal.spotto.object_id
  skip_service_principal_aad_check = true

  depends_on = [time_sleep.role_propagation, time_sleep.sp_propagation]
}

resource "random_uuid" "policy_assignment_exempt_role" {
  for_each = local.policy_assignment_exempt_scopes
}

resource "azurerm_role_definition" "policy_assignment_exempt" {
  for_each           = local.policy_assignment_exempt_scopes
  role_definition_id = random_uuid.policy_assignment_exempt_role[each.key].result
  name               = "${substr(var.policy_assignment_exempt_role_name, 0, 110)} ${substr(sha1(lower(each.key)), 0, 8)}"
  scope              = each.key
  description        = "Allows Spotto to exempt explicitly selected inherited Azure Policy assignments"

  permissions {
    actions = ["Microsoft.Authorization/policyAssignments/exempt/action"]
  }

  # Azure permits only one management group in a custom role's assignable scopes.
  assignable_scopes = [each.key]
}

resource "time_sleep" "policy_assignment_exempt_role_propagation" {
  for_each        = local.policy_assignment_exempt_scopes
  create_duration = var.custom_role_propagation_delay

  depends_on = [azurerm_role_definition.policy_assignment_exempt]
}

resource "azurerm_role_assignment" "policy_assignment_exempt" {
  for_each                         = local.policy_assignment_exempt_scopes
  scope                            = each.value
  role_definition_id               = azurerm_role_definition.policy_assignment_exempt[each.key].role_definition_resource_id
  principal_id                     = azuread_service_principal.spotto.object_id
  skip_service_principal_aad_check = true

  depends_on = [time_sleep.policy_assignment_exempt_role_propagation, time_sleep.sp_propagation]
}
