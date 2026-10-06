data "azurerm_client_config" "current" {}

data "azuread_client_config" "current" {}

data "azapi_client_config" "current" {}

data "azurerm_subscriptions" "current" {
  count = var.assign_reader_to_all_subscriptions ? 1 : 0
}

data "azurerm_role_definition" "reader" {
  name = "Reader"
}

data "azurerm_role_definition" "reservations_reader" {
  name = "Reservations Reader"
}

data "azurerm_role_definition" "reservations_contributor" {
  name = "Reservations Contributor"
}

data "azurerm_role_definition" "savings_plan_reader" {
  name = "Savings plan Reader"
}

data "azuread_service_principal" "msgraph" {
  count     = var.enable_graph_permission ? 1 : 0
  client_id = "00000003-0000-0000-c000-000000000000"
}

locals {
  tenant_id                      = coalesce(var.tenant_id, data.azurerm_client_config.current.tenant_id)
  normalized_tenant_id           = replace(lower(local.tenant_id), "-", "")
  tenant_root_scope              = "/"
  reservations_scope             = "/providers/Microsoft.Capacity"
  savings_plan_scope             = "/providers/Microsoft.BillingBenefits"
  default_management_group_id    = coalesce(var.root_management_group_id, local.tenant_id)
  effective_management_group_ids = length(var.management_group_ids) > 0 ? var.management_group_ids : toset([local.default_management_group_id])
  management_group_scope_map = length(var.management_group_ids) > 0 ? {
    for id in var.management_group_ids : "management-group:${lower(id)}" => "/providers/Microsoft.Management/managementGroups/${id}"
    } : {
    default = "/providers/Microsoft.Management/managementGroups/${local.default_management_group_id}"
  }
  extended_management_group_scope_map = var.assign_reader_to_all_subscriptions || length(var.management_group_ids) > 0 ? local.management_group_scope_map : {}
  extended_management_group_scopes    = toset(values(local.extended_management_group_scope_map))
  all_subscription_ids                = var.assign_reader_to_all_subscriptions ? [for sub in data.azurerm_subscriptions.current[0].subscriptions : sub.subscription_id] : []
  effective_subscription_ids          = var.assign_reader_to_all_subscriptions ? local.all_subscription_ids : var.subscription_ids
  subscription_scopes                 = [for id in local.effective_subscription_ids : "/subscriptions/${id}"]
  enable_log_analytics_reader         = var.enable_log_analytics_data_reader != null ? var.enable_log_analytics_data_reader : var.enable_log_analytics_reader
  spotto_application_tags = toset([
    "SpottoAzureOnboarding",
    "SpottoTenantId:${local.tenant_id}"
  ])
  graph_app_role_values = [
    "Application.Read.All",
    "RoleAssignmentSchedule.Read.Directory",
    "RoleEligibilitySchedule.Read.Directory",
    "RoleManagement.Read.Directory",
    "GroupMember.Read.All",
    "User.Read.All",
    "AuditLog.Read.All",
    "Policy.Read.All",
    "LicenseAssignment.Read.All",
    "Reports.Read.All",
    "Organization.Read.All"
  ]
  graph_app_role_ids = var.enable_graph_permission ? {
    for role_value in local.graph_app_role_values : role_value => one([
      for role in data.azuread_service_principal.msgraph[0].app_roles : role.id
      if role.value == role_value && contains(role.allowed_member_types, "Application")
    ])
  } : {}
  additional_graph_app_role_ids = {
    for role_value, role_id in local.graph_app_role_ids : role_value => role_id
    if role_value != "Application.Read.All"
  }
  custom_role_scope                           = try(local.subscription_scopes[0], null)
  secret_end_date                             = var.client_secret_end_date != null ? var.client_secret_end_date : (var.create_client_secret ? timeadd(time_static.secret_created[0].rfc3339, "8760h") : null)
  role_definition_base                        = "/providers/Microsoft.Authorization/roleDefinitions"
  reader_role_definition_id                   = "${local.role_definition_base}/${basename(trimsuffix(data.azurerm_role_definition.reader.role_definition_id, "/"))}"
  reservations_reader_role_definition_id      = "${local.role_definition_base}/${basename(trimsuffix(data.azurerm_role_definition.reservations_reader.role_definition_id, "/"))}"
  reservations_contributor_role_definition_id = "${local.role_definition_base}/${basename(trimsuffix(data.azurerm_role_definition.reservations_contributor.role_definition_id, "/"))}"
  savings_plan_reader_role_definition_id      = "${local.role_definition_base}/${basename(trimsuffix(data.azurerm_role_definition.savings_plan_reader.role_definition_id, "/"))}"
  root_reader_assignment_name                 = uuidv5("url", "${local.tenant_root_scope}|${local.reader_role_definition_id}|${azuread_service_principal.spotto.object_id}")
  reservations_assignment_name                = uuidv5("url", "${local.reservations_scope}|${local.reservations_reader_role_definition_id}|${azuread_service_principal.spotto.object_id}")
  reservations_contributor_assignment_name    = uuidv5("url", "${local.reservations_scope}|${local.reservations_contributor_role_definition_id}|${azuread_service_principal.spotto.object_id}")
  savings_plan_assignment_name                = uuidv5("url", "${local.savings_plan_scope}|${local.savings_plan_reader_role_definition_id}|${azuread_service_principal.spotto.object_id}")
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
  billing_export_storage_account_requested_name = var.create_billing_export_storage_account || var.billing_export_storage_account_id == null ? (
    var.billing_export_storage_account_name != null ? var.billing_export_storage_account_name : "billingexports${substr(local.normalized_tenant_id, length(local.normalized_tenant_id) - 10, 10)}"
  ) : split("/", var.billing_export_storage_account_id)[8]
  billing_export_storage_account_name = !var.enable_billing_exports ? null : (
    var.create_billing_export_storage_account ? azapi_resource.billing_export_storage_account[0].name : split("/", var.billing_export_storage_account_id)[8]
  )
  billing_export_storage_tags = {
    SpottoPurpose  = "BillingExports"
    SpottoTenantId = local.tenant_id
    spotto         = "billing-exports"
  }
  existing_billing_export_storage_subscription_id = var.billing_export_storage_account_id != null ? split("/", var.billing_export_storage_account_id)[2] : null
  billing_export_storage_subscription_id = coalesce(
    var.create_billing_export_storage_account ? var.billing_export_storage_subscription_id : local.existing_billing_export_storage_subscription_id,
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
  billing_export_management_group_recurring_exports = var.enable_billing_exports ? {
    for management_group_id in var.billing_export_management_group_ids : management_group_id => {
      management_group_id   = management_group_id
      scope                 = "/providers/Microsoft.Management/managementGroups/${management_group_id}"
      dataset_type          = "Usage"
      dataset_folder        = "actual"
      recurring_export_name = "spotto-usage-daily"
      root_folder_path      = "${var.billing_export_root_path}/management-groups/${management_group_id}/actual/recurring"
    }
  } : {}
  billing_backfill_month_keys = var.enable_billing_exports && var.enable_billing_export_backfill ? toset([
    for months_ago in range(1, var.billing_export_backfill_month_count + 1) : format("%02d", months_ago)
  ]) : toset([])
  billing_export_backfill_exports = var.enable_billing_exports && var.enable_billing_export_backfill ? {
    for pair in setproduct(values(local.billing_export_recurring_exports), local.billing_backfill_month_keys) :
    "${pair[0].subscription_id}|${pair[0].dataset_type}|months-ago-${pair[1]}" => {
      subscription_id  = pair[0].subscription_id
      dataset_type     = pair[0].dataset_type
      definition_type  = pair[0].definition_type
      dataset_folder   = pair[0].dataset_folder
      period_name      = formatdate("YYYYMM", time_offset.billing_backfill_period_start[pair[1]].rfc3339)
      from             = time_offset.billing_backfill_period_start[pair[1]].rfc3339
      to               = time_offset.billing_backfill_period_end[pair[1]].rfc3339
      export_name      = "spotto-${pair[0].dataset_folder}-backfill-${formatdate("YYYYMM", time_offset.billing_backfill_period_start[pair[1]].rfc3339)}"
      root_folder_path = "${var.billing_export_root_path}/${pair[0].subscription_id}/${pair[0].dataset_folder}/backfill/${formatdate("YYYYMM", time_offset.billing_backfill_period_start[pair[1]].rfc3339)}"
    }
  } : {}
  managed_subscription_billing_export_sources = [
    for export in values(local.billing_export_recurring_exports) : {
      datasetType = export.dataset_folder
      scopeType   = "subscription"
      scopePath   = "/subscriptions/${export.subscription_id}"
      exportName  = export.recurring_export_name
      destination = {
        storageAccountName = local.billing_export_storage_account_name
        container          = var.billing_export_container_name
        rootFolderPath     = export.root_folder_path
      }
    }
  ]
  managed_management_group_billing_export_sources = [
    for export in values(local.billing_export_management_group_recurring_exports) : {
      datasetType = "actual"
      scopeType   = "managementGroup"
      scopePath   = export.scope
      exportName  = export.recurring_export_name
      destination = {
        storageAccountName = local.billing_export_storage_account_name
        container          = var.billing_export_container_name
        rootFolderPath     = export.root_folder_path
      }
    }
  ]
  existing_billing_export_sources = [
    for source in var.existing_billing_export_sources : {
      datasetType = source.dataset_type
      scopeType   = source.scope_type
      scopePath   = trimsuffix(trimspace(source.scope_path), "/")
      exportName  = trimspace(source.export_name)
      destination = {
        storageAccountName = split("/", source.storage_account_id)[8]
        container          = lower(source.container_name)
        rootFolderPath     = trim(trimspace(source.root_folder_path), "/")
      }
    }
  ]
  azure_manual_onboarding_billing_export_sources = concat(
    local.managed_subscription_billing_export_sources,
    local.managed_management_group_billing_export_sources,
    local.existing_billing_export_sources
  )
  azure_manual_onboarding_billing_export_source_identities = [
    for source in local.azure_manual_onboarding_billing_export_sources : lower(
      "${source.datasetType}|${source.scopeType}|${source.scopePath}|${source.exportName}"
    )
  ]
  azure_manual_onboarding_billing_exports_within_count_limit = length(local.azure_manual_onboarding_billing_export_sources) <= 50
  azure_manual_onboarding_billing_exports_within_size_limit = length(base64encode(jsonencode({
    sources = local.azure_manual_onboarding_billing_export_sources
  }))) <= 32768
  azure_manual_onboarding_billing_exports_eligible = (
    local.azure_manual_onboarding_billing_exports_within_count_limit &&
    local.azure_manual_onboarding_billing_exports_within_size_limit
  )
  azure_manual_onboarding_credentials = merge(
    {
      tenantId = local.tenant_id
      clientId = azuread_application.spotto.client_id
    },
    var.create_client_secret ? {
      clientSecret          = azuread_application_password.spotto[0].value
      clientSecretExpiresAt = formatdate("YYYY-MM-DD", azuread_application_password.spotto[0].end_date)
    } : {}
  )
  azure_manual_onboarding_payload = merge(
    {
      schemaVersion = 1
      kind          = "spotto.azure.manual-onboarding"
      credentials   = local.azure_manual_onboarding_credentials
    },
    length(local.azure_manual_onboarding_billing_export_sources) > 0 && local.azure_manual_onboarding_billing_exports_eligible ? {
      billingExports = {
        sources = local.azure_manual_onboarding_billing_export_sources
      }
    } : {}
  )
  existing_billing_export_container_scopes = toset([
    for source in var.existing_billing_export_sources :
    "${source.storage_account_id}/blobServices/default/containers/${source.container_name}"
    if var.grant_existing_billing_export_storage_reader && !(
      var.enable_billing_exports &&
      !var.create_billing_export_storage_account &&
      lower(source.storage_account_id) == try(lower(var.billing_export_storage_account_id), "") &&
      lower(source.container_name) == lower(var.billing_export_container_name)
    )
  ])
  optional_write_role_enabled = var.grant_optional_write_permissions || var.grant_policy_exemption_permissions
  custom_role_actions = concat(var.grant_optional_write_permissions ? [
    "Microsoft.Advisor/recommendations/write",
    "Microsoft.Advisor/recommendations/suppressions/write",
    "Microsoft.Advisor/recommendations/suppressions/delete",
    "Microsoft.Storage/storageAccounts/inventoryPolicies/write",
    "Microsoft.Storage/storageAccounts/inventoryPolicies/read"
    ] : [], var.grant_policy_exemption_permissions ? [
    "Microsoft.Authorization/policyExemptions/write",
    "Microsoft.Authorization/policyAssignments/exempt/action"
  ] : [])
  policy_assignment_exempt_scopes = toset([
    for scope in var.policy_assignment_exempt_scopes : trimsuffix(trimspace(scope), "/")
  ])
}

resource "azuread_application" "spotto" {
  display_name = var.app_name
  tags         = local.spotto_application_tags

  dynamic "required_resource_access" {
    for_each = var.enable_graph_permission ? [1] : []

    content {
      resource_app_id = "00000003-0000-0000-c000-000000000000"

      dynamic "resource_access" {
        for_each = local.graph_app_role_ids

        content {
          id   = resource_access.value
          type = "Role"
        }
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
      condition = (
        var.create_billing_export_storage_account ||
        var.billing_export_storage_subscription_id == null ||
        lower(var.billing_export_storage_subscription_id) == lower(local.existing_billing_export_storage_subscription_id)
      )
      error_message = "When using existing billing export storage, billing_export_storage_subscription_id must be omitted or match the subscription in billing_export_storage_account_id."
    }
    precondition {
      condition     = !var.enable_billing_exports || length(local.effective_subscription_ids) > 0
      error_message = "When enable_billing_exports is true, at least one effective subscription must be resolved for Cost Management exports."
    }
    precondition {
      condition     = !local.optional_write_role_enabled || length(local.subscription_scopes) > 0
      error_message = "When optional write or policy exemption permissions are enabled, at least one effective subscription must be resolved."
    }
    precondition {
      condition = (
        lower(local.tenant_id) == lower(data.azurerm_client_config.current.tenant_id) &&
        lower(local.tenant_id) == lower(data.azuread_client_config.current.tenant_id) &&
        lower(local.tenant_id) == lower(data.azapi_client_config.current.tenant_id)
      )
      error_message = "tenant_id and the AzureRM, AzureAD, and AzAPI provider tenants must match. Cross-tenant onboarding is not supported."
    }
    precondition {
      condition     = var.grant_policy_exemption_permissions || length(local.policy_assignment_exempt_scopes) == 0
      error_message = "policy_assignment_exempt_scopes requires grant_policy_exemption_permissions to be true."
    }
    precondition {
      condition     = length(local.normalized_tenant_id) >= 10
      error_message = "The effective tenant ID must contain at least 10 alphanumeric characters for deterministic billing storage naming."
    }
    precondition {
      condition     = length(distinct(local.azure_manual_onboarding_billing_export_source_identities)) == length(local.azure_manual_onboarding_billing_export_source_identities)
      error_message = "Managed and existing billing export sources must not contain duplicate dataset, scope, and export identities."
    }
    precondition {
      condition = alltrue([
        for source in local.azure_manual_onboarding_billing_export_sources :
        length(source.destination.rootFolderPath) > 0 &&
        length(source.destination.rootFolderPath) <= 1024 &&
        can(regex("^[^%\\\\?#\\x00-\\x1F\\x7F]+$", source.destination.rootFolderPath)) &&
        alltrue([for segment in split("/", source.destination.rootFolderPath) : length(segment) > 0 && !contains([".", ".."], segment)])
      ])
      error_message = "Every billing export source must produce a non-empty portal-safe root folder path of at most 1024 characters."
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
  count          = var.create_client_secret ? 1 : 0
  application_id = azuread_application.spotto.id
  display_name   = "spotto-onboarding"
  end_date       = local.secret_end_date
}

resource "azuread_app_role_assignment" "graph_app_read_all" {
  count = var.enable_graph_permission ? 1 : 0

  app_role_id         = local.graph_app_role_ids["Application.Read.All"]
  principal_object_id = azuread_service_principal.spotto.object_id
  resource_object_id  = data.azuread_service_principal.msgraph[0].object_id

  depends_on = [time_sleep.sp_propagation]
}

resource "azuread_app_role_assignment" "graph_additional_permissions" {
  for_each = local.additional_graph_app_role_ids

  app_role_id         = each.value
  principal_object_id = azuread_service_principal.spotto.object_id
  resource_object_id  = data.azuread_service_principal.msgraph[0].object_id

  depends_on = [time_sleep.sp_propagation]
}

resource "time_sleep" "sp_propagation" {
  create_duration = var.service_principal_propagation_delay

  depends_on = [azuread_service_principal.spotto]
}
