mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id       = "11111111-2222-3333-4444-555555555555"
      subscription_id = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
    }
  }

  mock_data "azurerm_role_definition" {
    defaults = {
      role_definition_id = "/providers/Microsoft.Authorization/roleDefinitions/00000000-0000-0000-0000-000000000001"
    }
  }

  mock_data "azurerm_subscriptions" {
    defaults = {
      subscriptions = [{
        display_name          = "Example"
        id                    = "/subscriptions/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
        location_placement_id = "Public_2014-09-01"
        quota_id              = "PayAsYouGo_2014-09-01"
        spending_limit        = "Off"
        state                 = "Enabled"
        subscription_id       = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
        tags                  = {}
        tenant_id             = "11111111-2222-3333-4444-555555555555"
      }]
    }
  }
}

mock_provider "azuread" {
  mock_data "azuread_client_config" {
    defaults = {
      tenant_id = "11111111-2222-3333-4444-555555555555"
    }
  }

  mock_data "azuread_service_principal" {
    defaults = {
      client_id    = "00000003-0000-0000-c000-000000000000"
      object_id    = "00000003-0000-0000-c000-000000000000"
      display_name = "Microsoft Graph"
      app_roles = [
        {
          allowed_member_types = ["Application"]
          description          = "Application.Read.All"
          display_name         = "Application.Read.All"
          enabled              = true
          id                   = "40000000-0000-0000-0000-000000000001"
          value                = "Application.Read.All"
        },
        {
          allowed_member_types = ["Application"]
          description          = "RoleAssignmentSchedule.Read.Directory"
          display_name         = "RoleAssignmentSchedule.Read.Directory"
          enabled              = true
          id                   = "40000000-0000-0000-0000-000000000002"
          value                = "RoleAssignmentSchedule.Read.Directory"
        },
        {
          allowed_member_types = ["Application"]
          description          = "RoleEligibilitySchedule.Read.Directory"
          display_name         = "RoleEligibilitySchedule.Read.Directory"
          enabled              = true
          id                   = "40000000-0000-0000-0000-000000000003"
          value                = "RoleEligibilitySchedule.Read.Directory"
        },
        {
          allowed_member_types = ["Application"]
          description          = "RoleManagement.Read.Directory"
          display_name         = "RoleManagement.Read.Directory"
          enabled              = true
          id                   = "40000000-0000-0000-0000-000000000004"
          value                = "RoleManagement.Read.Directory"
        },
        {
          allowed_member_types = ["Application"]
          description          = "GroupMember.Read.All"
          display_name         = "GroupMember.Read.All"
          enabled              = true
          id                   = "40000000-0000-0000-0000-000000000005"
          value                = "GroupMember.Read.All"
        },
        {
          allowed_member_types = ["Application"]
          description          = "User.Read.All"
          display_name         = "User.Read.All"
          enabled              = true
          id                   = "40000000-0000-0000-0000-000000000006"
          value                = "User.Read.All"
        },
        {
          allowed_member_types = ["Application"]
          description          = "AuditLog.Read.All"
          display_name         = "AuditLog.Read.All"
          enabled              = true
          id                   = "40000000-0000-0000-0000-000000000007"
          value                = "AuditLog.Read.All"
        },
        {
          allowed_member_types = ["Application"]
          description          = "Policy.Read.All"
          display_name         = "Policy.Read.All"
          enabled              = true
          id                   = "40000000-0000-0000-0000-000000000008"
          value                = "Policy.Read.All"
        },
        {
          allowed_member_types = ["Application"]
          description          = "LicenseAssignment.Read.All"
          display_name         = "LicenseAssignment.Read.All"
          enabled              = true
          id                   = "40000000-0000-0000-0000-000000000009"
          value                = "LicenseAssignment.Read.All"
        }
      ]
    }
  }

  mock_resource "azuread_application" {
    override_during = plan

    defaults = {
      app_role_ids                = {}
      application_id              = "10000000-0000-0000-0000-000000000001"
      client_id                   = "10000000-0000-0000-0000-000000000001"
      disabled_by_microsoft       = ""
      id                          = "/applications/10000000-0000-0000-0000-000000000002"
      logo_url                    = ""
      oauth2_permission_scope_ids = {}
      object_id                   = "10000000-0000-0000-0000-000000000002"
      publisher_domain            = "example.onmicrosoft.com"
      template_id                 = ""
    }
  }

  mock_resource "azuread_service_principal" {
    override_during = plan

    defaults = {
      app_role_ids                = {}
      app_roles                   = []
      application_id              = "10000000-0000-0000-0000-000000000001"
      application_tenant_id       = "11111111-2222-3333-4444-555555555555"
      client_id                   = "10000000-0000-0000-0000-000000000001"
      display_name                = "Spotto"
      homepage_url                = ""
      id                          = "/servicePrincipals/10000000-0000-0000-0000-000000000003"
      logout_url                  = ""
      oauth2_permission_scope_ids = {}
      oauth2_permission_scopes    = []
      object_id                   = "10000000-0000-0000-0000-000000000003"
      redirect_uris               = []
      saml_metadata_url           = ""
      service_principal_names     = ["10000000-0000-0000-0000-000000000001"]
      sign_in_audience            = "AzureADMyOrg"
      tags                        = []
      type                        = "Application"
    }
  }

  mock_resource "azuread_application_password" {
    override_during = plan

    defaults = {
      application_id        = "10000000-0000-0000-0000-000000000001"
      application_object_id = "10000000-0000-0000-0000-000000000002"
      display_name          = "spotto-onboarding"
      end_date              = "2027-08-31T00:00:00Z"
      id                    = "/applications/10000000-0000-0000-0000-000000000002/password/30000000-0000-0000-0000-000000000001"
      key_id                = "30000000-0000-0000-0000-000000000001"
      start_date            = "2026-08-31T00:00:00Z"
      value                 = "fake-test-secret"
    }
  }
}

mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      tenant_id = "11111111-2222-3333-4444-555555555555"
    }
  }
}

mock_provider "random" {
  mock_resource "random_uuid" {
    override_during = plan

    defaults = {
      result = "20000000-0000-0000-0000-000000000001"
    }
  }
}

mock_provider "time" {
  mock_resource "time_static" {
    defaults = {
      rfc3339 = "2026-08-31T00:00:00Z"
    }
  }
}

run "recommended_defaults_are_least_privilege" {
  command = plan

  variables {
    subscription_ids        = ["aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"]
    create_client_secret    = false
    enable_graph_permission = false
  }

  assert {
    condition     = length(azapi_resource.reservations_contributor) == 0
    error_message = "Reservations Contributor must be opt-in in the Recommended-equivalent defaults."
  }

  assert {
    condition     = length(azurerm_role_assignment.key_vault_reader_subscription) == 1
    error_message = "Key Vault Reader must be assigned on targeted subscriptions when no management-group coverage is selected."
  }

  assert {
    condition     = length(azurerm_role_assignment.reader_management_group) == 0
    error_message = "Targeted subscription mode must not grant inherited Azure Reader at the tenant-root management group."
  }

  assert {
    condition     = length(azurerm_role_assignment.management_group_reader) == 1
    error_message = "Targeted subscription mode must retain Management Group Reader hierarchy and authorization metadata."
  }

  assert {
    condition = alltrue([
      for role_id in [
        local.reader_role_definition_id,
        local.reservations_reader_role_definition_id,
        local.reservations_contributor_role_definition_id,
        local.savings_plan_reader_role_definition_id
      ] : startswith(role_id, "/providers/Microsoft.Authorization/roleDefinitions/") &&
      length(regexall("/providers/Microsoft.Authorization/roleDefinitions/", role_id)) == 1
    ])
    error_message = "Built-in role definition IDs must contain exactly one ARM role-definition prefix."
  }

  assert {
    condition     = length(azurerm_role_assignment.security_reader) == 1
    error_message = "Security Reader must remain enabled on targeted subscriptions."
  }

  assert {
    condition = local.graph_app_role_values == [
      "Application.Read.All",
      "RoleAssignmentSchedule.Read.Directory",
      "RoleEligibilitySchedule.Read.Directory",
      "RoleManagement.Read.Directory",
      "GroupMember.Read.All",
      "User.Read.All",
      "AuditLog.Read.All",
      "Policy.Read.All",
      "LicenseAssignment.Read.All"
    ]
    error_message = "The Microsoft Graph permission allowlist must remain exactly aligned with PowerShell."
  }

  assert {
    condition = toset(azuread_application.spotto.tags) == toset([
      "SpottoAzureOnboarding",
      "SpottoTenantId:11111111-2222-3333-4444-555555555555"
    ])
    error_message = "The application must carry the PowerShell-compatible Spotto ownership tags."
  }
}

run "graph_permissions_resolve_and_assign_exact_app_roles" {
  command = plan

  variables {
    subscription_ids     = ["aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"]
    create_client_secret = false
  }

  assert {
    condition = length(local.graph_app_role_ids) == 9 && alltrue([
      for role_name, expected_id in {
        "Application.Read.All"                   = "40000000-0000-0000-0000-000000000001"
        "RoleAssignmentSchedule.Read.Directory"  = "40000000-0000-0000-0000-000000000002"
        "RoleEligibilitySchedule.Read.Directory" = "40000000-0000-0000-0000-000000000003"
        "RoleManagement.Read.Directory"          = "40000000-0000-0000-0000-000000000004"
        "GroupMember.Read.All"                   = "40000000-0000-0000-0000-000000000005"
        "User.Read.All"                          = "40000000-0000-0000-0000-000000000006"
        "AuditLog.Read.All"                      = "40000000-0000-0000-0000-000000000007"
        "Policy.Read.All"                        = "40000000-0000-0000-0000-000000000008"
        "LicenseAssignment.Read.All"             = "40000000-0000-0000-0000-000000000009"
      } : local.graph_app_role_ids[role_name] == expected_id
    ])
    error_message = "Microsoft Graph permission names must resolve to the exact mocked application role IDs."
  }

  assert {
    condition = (
      length(azuread_app_role_assignment.graph_app_read_all) == 1 &&
      azuread_app_role_assignment.graph_app_read_all[0].app_role_id == "40000000-0000-0000-0000-000000000001"
    )
    error_message = "Application.Read.All must receive exactly one dedicated app-role assignment."
  }

  assert {
    condition = (
      length(azuread_app_role_assignment.graph_additional_permissions) == 8 &&
      alltrue([
        for role_name, assignment in azuread_app_role_assignment.graph_additional_permissions :
        assignment.app_role_id == local.graph_app_role_ids[role_name]
      ])
    )
    error_message = "The remaining eight Microsoft Graph roles must each receive the exact resolved app-role ID."
  }
}

run "explicit_management_groups_receive_governance_roles" {
  command = plan

  variables {
    subscription_ids        = ["aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"]
    management_group_ids    = ["landing-zone"]
    create_client_secret    = false
    enable_graph_permission = false
  }

  assert {
    condition     = length(azurerm_role_assignment.monitoring_reader_management_group) == 1
    error_message = "Explicit management groups must receive Monitoring Reader when enabled."
  }

  assert {
    condition     = length(azurerm_role_assignment.key_vault_reader_management_group) == 1
    error_message = "Explicit management groups must receive Key Vault Reader."
  }

  assert {
    condition     = length(azurerm_role_assignment.key_vault_reader_subscription) == 1
    error_message = "Explicit management groups must not remove Key Vault Reader from selected subscriptions whose ancestry is unknown."
  }

  assert {
    condition     = length(azurerm_role_assignment.reader_management_group) == 1
    error_message = "An explicitly selected management group must receive Azure Reader when governance roles are enabled."
  }
}

run "tenant_wide_defaults_use_root_and_management_group_coverage" {
  command = plan

  variables {
    assign_reader_to_all_subscriptions = true
    create_client_secret               = false
    enable_graph_permission            = false
  }

  assert {
    condition     = length(azapi_resource.reader_root) == 1 && length(azurerm_role_assignment.reader) == 0
    error_message = "Tenant-wide mode must use one root Reader assignment instead of subscription Reader assignments."
  }

  assert {
    condition = (
      length(azurerm_role_assignment.key_vault_reader_management_group) == 1 &&
      length(azurerm_role_assignment.key_vault_reader_subscription) == 0
    )
    error_message = "Tenant-wide default mode must use root-management-group Key Vault coverage without duplicate subscription assignments."
  }

  assert {
    condition = (
      length(azurerm_role_assignment.reader_management_group) == 1 &&
      length(azurerm_role_assignment.management_group_reader) == 1 &&
      length(azurerm_role_assignment.monitoring_reader_management_group) == 1 &&
      length(azurerm_role_assignment.log_analytics_reader_management_group) == 1
    )
    error_message = "Tenant-wide defaults must preserve the expected root management-group governance and monitoring roles."
  }
}

run "tenant_wide_explicit_management_groups_keep_subscription_key_vault_fallback" {
  command = plan

  variables {
    assign_reader_to_all_subscriptions = true
    management_group_ids               = ["landing-zone"]
    create_client_secret               = false
    enable_graph_permission            = false
  }

  assert {
    condition = (
      length(azurerm_role_assignment.key_vault_reader_management_group) == 1 &&
      length(azurerm_role_assignment.key_vault_reader_subscription) == 1
    )
    error_message = "Explicit management groups must retain current-subscription Key Vault fallback when tenant-wide ancestry is not proven."
  }

  assert {
    condition = (
      one(values(azurerm_role_assignment.key_vault_reader_management_group)).scope == "/providers/Microsoft.Management/managementGroups/landing-zone" &&
      one(values(azurerm_role_assignment.key_vault_reader_subscription)).scope == "/subscriptions/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
    )
    error_message = "Tenant-wide explicit management-group Key Vault assignments must use the selected management group and resolved subscription scopes."
  }
}

run "optional_write_and_policy_exemption_roles_use_exact_actions_and_scopes" {
  command = plan

  variables {
    subscription_ids                   = ["aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"]
    create_client_secret               = false
    enable_graph_permission            = false
    grant_optional_write_permissions   = true
    grant_policy_exemption_permissions = true
    policy_assignment_exempt_scopes = [
      "/providers/Microsoft.Management/managementGroups/landing-zone"
    ]
  }

  assert {
    condition = toset(azurerm_role_definition.spotto_write[0].permissions[0].actions) == toset([
      "Microsoft.Advisor/recommendations/write",
      "Microsoft.Advisor/recommendations/suppressions/write",
      "Microsoft.Advisor/recommendations/suppressions/delete",
      "Microsoft.Storage/storageAccounts/inventoryPolicies/write",
      "Microsoft.Storage/storageAccounts/inventoryPolicies/read",
      "Microsoft.Authorization/policyExemptions/write",
      "Microsoft.Authorization/policyAssignments/exempt/action"
    ])
    error_message = "The subscription custom role must contain exactly the approved optional-write and policy-exemption actions."
  }

  assert {
    condition = (
      azurerm_role_definition.spotto_write[0].scope == "/subscriptions/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee" &&
      toset(azurerm_role_definition.spotto_write[0].assignable_scopes) == toset(["/subscriptions/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"]) &&
      length(azurerm_role_assignment.spotto_write) == 1
    )
    error_message = "The optional write role and assignment must remain limited to the selected subscription."
  }

  assert {
    condition = (
      toset(azurerm_role_definition.policy_assignment_exempt["/providers/Microsoft.Management/managementGroups/landing-zone"].permissions[0].actions) == toset(["Microsoft.Authorization/policyAssignments/exempt/action"]) &&
      toset(azurerm_role_definition.policy_assignment_exempt["/providers/Microsoft.Management/managementGroups/landing-zone"].assignable_scopes) == toset(["/providers/Microsoft.Management/managementGroups/landing-zone"]) &&
      azurerm_role_assignment.policy_assignment_exempt["/providers/Microsoft.Management/managementGroups/landing-zone"].scope == "/providers/Microsoft.Management/managementGroups/landing-zone"
    )
    error_message = "The inherited-policy role must contain only the exempt action and remain limited to its explicit management group."
  }
}

run "policy_exemption_scopes_require_explicit_consent" {
  command = plan

  variables {
    subscription_ids        = ["aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"]
    create_client_secret    = false
    enable_graph_permission = false
    policy_assignment_exempt_scopes = [
      "/providers/Microsoft.Management/managementGroups/landing-zone"
    ]
  }

  expect_failures = [azuread_application.spotto]
}

run "managed_exports_use_owned_deterministic_storage_and_handoff" {
  command = plan

  variables {
    subscription_ids                    = ["aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"]
    create_client_secret                = false
    enable_graph_permission             = false
    enable_billing_exports              = true
    enable_billing_export_backfill      = false
    billing_export_management_group_ids = ["landing-zone"]
  }

  assert {
    condition     = azapi_resource.billing_export_storage_account[0].name == "billingexports5555555555"
    error_message = "The default storage name must match the deterministic PowerShell tenant convention."
  }

  assert {
    condition = (
      length(azapi_resource.billing_export_storage_account[0].tags) == 3 &&
      azapi_resource.billing_export_storage_account[0].tags["SpottoPurpose"] == "BillingExports" &&
      azapi_resource.billing_export_storage_account[0].tags["SpottoTenantId"] == "11111111-2222-3333-4444-555555555555" &&
      azapi_resource.billing_export_storage_account[0].tags["spotto"] == "billing-exports"
    )
    error_message = "Module-created storage must carry the PowerShell-compatible ownership tags."
  }

  assert {
    condition     = length(azapi_resource.billing_export_management_group_recurring) == 1
    error_message = "An explicit management-group target must receive a Usage export."
  }

  assert {
    condition     = length(azapi_resource_action.billing_export_recurring_run) == 0
    error_message = "Imperative recurring export runs must be disabled by default because AzAPI repeats them on apply."
  }

  assert {
    condition     = jsondecode(output.azure_manual_onboarding_json).schemaVersion == 1
    error_message = "The handoff payload must use schema version 1."
  }

  assert {
    condition     = jsondecode(output.azure_manual_onboarding_json).kind == "spotto.azure.manual-onboarding"
    error_message = "The handoff payload kind must match the portal contract."
  }

  assert {
    condition     = length(jsondecode(output.azure_manual_onboarding_json).billingExports.sources) == 3
    error_message = "The handoff must contain two subscription datasets and one management-group Usage source."
  }

  assert {
    condition     = output.azure_manual_onboarding_billing_exports_eligible
    error_message = "A normal managed export configuration must remain eligible for the portal handoff."
  }
}

run "explicit_write_role_and_export_actions_are_opt_in" {
  command = plan

  variables {
    subscription_ids                     = ["aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"]
    create_client_secret                 = false
    enable_graph_permission              = false
    enable_reservations_contributor      = true
    enable_billing_exports               = true
    billing_export_backfill_month_count  = 1
    enable_billing_export_immediate_runs = true
    enable_billing_export_backfill_runs  = true
  }

  assert {
    condition     = length(azapi_resource.reservations_contributor) == 1
    error_message = "Reservations Contributor must be available only through explicit opt-in."
  }

  assert {
    condition     = length(azapi_resource_action.billing_export_recurring_run) == 2
    error_message = "Explicit immediate-run opt-in must queue both recurring dataset exports."
  }

  assert {
    condition     = length(azapi_resource_action.billing_export_backfill_run) == 2
    error_message = "Explicit backfill-run opt-in must queue both dataset backfills."
  }
}

run "secret_bearing_handoff_uses_the_versioned_contract" {
  command   = apply
  state_key = "secret-handoff"

  variables {
    subscription_ids        = ["aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"]
    enable_graph_permission = false
  }

  assert {
    condition     = jsondecode(output.azure_manual_onboarding_json).credentials.clientSecret == "fake-test-secret"
    error_message = "The sensitive handoff must contain the generated client secret when secret creation is enabled."
  }

  assert {
    condition     = jsondecode(output.azure_manual_onboarding_json).credentials.clientSecretExpiresAt == "2027-08-31"
    error_message = "The sensitive handoff must contain the generated client-secret expiry date."
  }
}

run "existing_export_sources_are_handed_off_without_implicit_blob_access" {
  command = plan

  variables {
    subscription_ids        = ["aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"]
    create_client_secret    = false
    enable_graph_permission = false
    existing_billing_export_sources = [{
      dataset_type       = "actual"
      scope_type         = "billingProfile"
      scope_path         = "/providers/Microsoft.Billing/billingAccounts/account-1/billingProfiles/profile-1"
      export_name        = "daily-actual"
      storage_account_id = "/subscriptions/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/resourceGroups/exports/providers/Microsoft.Storage/storageAccounts/existingexports"
      container_name     = "cost-exports"
      root_folder_path   = "daily/actual"
    }]
  }

  assert {
    condition     = length(azurerm_role_assignment.existing_billing_export_storage_reader) == 0
    error_message = "Existing export storage must not receive Blob Data Reader without explicit authorization."
  }

  assert {
    condition     = jsondecode(output.azure_manual_onboarding_json).billingExports.sources[0].scopeType == "billingProfile"
    error_message = "Existing broad-scope exports must be represented in the portal handoff."
  }
}

run "existing_export_blob_access_is_explicit" {
  command = plan

  variables {
    subscription_ids                             = ["aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"]
    create_client_secret                         = false
    enable_graph_permission                      = false
    grant_existing_billing_export_storage_reader = true
    existing_billing_export_sources = [{
      dataset_type       = "actual"
      scope_type         = "billingProfile"
      scope_path         = "/providers/Microsoft.Billing/billingAccounts/account-1/billingProfiles/profile-1"
      export_name        = "daily-actual"
      storage_account_id = "/subscriptions/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/resourceGroups/exports/providers/Microsoft.Storage/storageAccounts/existingexports"
      container_name     = "cost-exports"
      root_folder_path   = "daily/actual"
    }]
  }

  assert {
    condition     = length(azurerm_role_assignment.existing_billing_export_storage_reader) == 1
    error_message = "Explicit authorization must grant container-level Blob Data Reader for declared existing export destinations."
  }
}

run "module_managed_existing_storage_is_not_double_assigned" {
  command = plan

  variables {
    subscription_ids                      = ["aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"]
    create_client_secret                  = false
    enable_graph_permission               = false
    enable_billing_exports                = true
    enable_billing_export_backfill        = false
    create_billing_export_storage_account = false
    billing_export_storage_account_id     = "/subscriptions/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/resourceGroups/exports/providers/Microsoft.Storage/storageAccounts/existingexports"
    existing_billing_export_sources = [{
      dataset_type       = "actual"
      scope_type         = "billingProfile"
      scope_path         = "/providers/Microsoft.Billing/billingAccounts/account-1/billingProfiles/profile-1"
      export_name        = "daily-actual"
      storage_account_id = "/subscriptions/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/resourceGroups/exports/providers/Microsoft.Storage/storageAccounts/existingexports"
      container_name     = "spotto-cost-exports"
      root_folder_path   = "daily/actual"
    }]
  }

  assert {
    condition     = length(azurerm_role_assignment.billing_export_storage_reader) == 1 && length(azurerm_role_assignment.existing_billing_export_storage_reader) == 0
    error_message = "A module-managed existing container must receive exactly one Blob Data Reader assignment."
  }

  assert {
    condition     = length(azapi_update_resource.billing_export_storage_account_settings) == 0
    error_message = "Existing storage network settings must remain untouched without explicit authorization."
  }

  assert {
    condition     = jsondecode(output.azure_manual_onboarding_json).billingExports.sources[0].destination.storageAccountName == "existingexports"
    error_message = "Managed export handoff sources must use the actual existing storage account name."
  }
}

run "existing_storage_network_changes_are_explicit" {
  command = plan

  variables {
    subscription_ids                                      = ["aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"]
    create_client_secret                                  = false
    enable_graph_permission                               = false
    enable_billing_exports                                = true
    enable_billing_export_backfill                        = false
    create_billing_export_storage_account                 = false
    billing_export_storage_account_id                     = "/subscriptions/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/resourceGroups/exports/providers/Microsoft.Storage/storageAccounts/existingexports"
    allow_existing_billing_export_storage_network_changes = true
  }

  assert {
    condition     = length(azapi_update_resource.billing_export_storage_account_settings) == 1
    error_message = "Explicit authorization must enable management of existing storage network settings."
  }

  assert {
    condition     = azapi_update_resource.billing_export_storage_account_settings[0].body.properties.networkAcls.defaultAction == "Allow"
    error_message = "The explicit network mutation must remain visible in the plan."
  }
}

run "existing_storage_subscription_override_must_match_resource_id" {
  command = plan

  variables {
    subscription_ids                       = ["aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"]
    create_client_secret                   = false
    enable_graph_permission                = false
    enable_billing_exports                 = true
    enable_billing_export_backfill         = false
    create_billing_export_storage_account  = false
    billing_export_storage_account_id      = "/subscriptions/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/resourceGroups/exports/providers/Microsoft.Storage/storageAccounts/existingexports"
    billing_export_storage_subscription_id = "bbbbbbbb-cccc-dddd-eeee-ffffffffffff"
  }

  expect_failures = [azuread_application.spotto]
}

run "initial_backfill_has_plan_known_instances" {
  command   = apply
  state_key = "backfill-outputs"

  variables {
    subscription_ids                    = ["aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"]
    create_client_secret                = false
    enable_graph_permission             = false
    enable_billing_exports              = true
    billing_export_backfill_month_count = 2
  }

  override_resource {
    target = time_offset.billing_backfill_period_start["01"]
    values = {
      rfc3339 = "2026-07-01T00:00:00Z"
    }
  }

  override_resource {
    target = time_offset.billing_backfill_period_start["02"]
    values = {
      rfc3339 = "2026-06-01T00:00:00Z"
    }
  }

  override_resource {
    target = azapi_resource.billing_export_resource_group[0]
    values = {
      id = "/subscriptions/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/resourceGroups/rg-spotto-cost-exports"
    }
  }

  override_resource {
    target = azapi_resource.billing_export_storage_account[0]
    values = {
      id = "/subscriptions/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/resourceGroups/rg-spotto-cost-exports/providers/Microsoft.Storage/storageAccounts/billingexports5555555555"
    }
  }

  override_resource {
    target = azapi_resource.billing_export_container[0]
    values = {
      id = "/subscriptions/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/resourceGroups/rg-spotto-cost-exports/providers/Microsoft.Storage/storageAccounts/billingexports5555555555/blobServices/default/containers/spotto-cost-exports"
    }
  }

  assert {
    condition     = length(azapi_resource.billing_export_backfill) == 4
    error_message = "Initial billing plan must create two datasets for each requested backfill month without unknown for_each keys."
  }

  assert {
    condition = toset(keys(output.billing_export_backfill_export_ids)) == toset([
      "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee|ActualCost|202606",
      "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee|ActualCost|202607",
      "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee|AmortizedCost|202606",
      "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee|AmortizedCost|202607"
    ])
    error_message = "The compatibility backfill output must retain calendar-keyed YYYYMM addresses."
  }

  assert {
    condition = toset(keys(output.billing_export_backfill_export_stable_ids)) == toset([
      "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee|ActualCost|months-ago-01",
      "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee|ActualCost|months-ago-02",
      "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee|AmortizedCost|months-ago-01",
      "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee|AmortizedCost|months-ago-02"
    ])
    error_message = "The stable backfill output must expose plan-known months-ago keys."
  }
}

run "existing_export_scope_type_must_match_path" {
  command = plan

  variables {
    subscription_ids        = ["aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"]
    create_client_secret    = false
    enable_graph_permission = false
    existing_billing_export_sources = [{
      dataset_type       = "actual"
      scope_type         = "subscription"
      scope_path         = "/providers/Microsoft.Billing/billingAccounts/account-1"
      export_name        = "daily-actual"
      storage_account_id = "/subscriptions/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/resourceGroups/exports/providers/Microsoft.Storage/storageAccounts/existingexports"
      container_name     = "cost-exports"
      root_folder_path   = "daily/actual"
    }]
  }

  expect_failures = [var.existing_billing_export_sources]
}

run "existing_export_root_folder_must_match_portal_contract" {
  command = plan

  variables {
    subscription_ids        = ["aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"]
    create_client_secret    = false
    enable_graph_permission = false
    existing_billing_export_sources = [{
      dataset_type       = "actual"
      scope_type         = "subscription"
      scope_path         = "/subscriptions/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
      export_name        = "daily-actual"
      storage_account_id = "/subscriptions/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/resourceGroups/exports/providers/Microsoft.Storage/storageAccounts/existingexports"
      container_name     = "cost-exports"
      root_folder_path   = "../unsafe"
    }]
  }

  expect_failures = [var.existing_billing_export_sources]
}

run "managed_and_existing_handoff_sources_must_be_unique" {
  command = plan

  variables {
    subscription_ids               = ["aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"]
    create_client_secret           = false
    enable_graph_permission        = false
    enable_billing_exports         = true
    enable_billing_export_backfill = false
    billing_export_dataset_types   = ["ActualCost"]
    existing_billing_export_sources = [{
      dataset_type       = "actual"
      scope_type         = "subscription"
      scope_path         = "/subscriptions/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
      export_name        = "spotto-actual-daily"
      storage_account_id = "/subscriptions/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/resourceGroups/exports/providers/Microsoft.Storage/storageAccounts/existingexports"
      container_name     = "cost-exports"
      root_folder_path   = "spotto/actual"
    }]
  }

  expect_failures = [azuread_application.spotto]
}

run "management_group_ids_must_be_normalized" {
  command = plan

  variables {
    subscription_ids        = ["aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"]
    management_group_ids    = [" landing-zone "]
    create_client_secret    = false
    enable_graph_permission = false
  }

  expect_failures = [var.management_group_ids]
}

run "root_and_billing_management_group_ids_must_be_normalized" {
  command = plan

  variables {
    subscription_ids                    = ["aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"]
    root_management_group_id            = " tenant-root "
    billing_export_management_group_ids = [" billing-root "]
    create_client_secret                = false
    enable_graph_permission             = false
  }

  expect_failures = [
    var.root_management_group_id,
    var.billing_export_management_group_ids
  ]
}

run "subscription_ids_must_be_case_insensitively_unique" {
  command = plan

  variables {
    subscription_ids = [
      "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
      "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"
    ]
    create_client_secret    = false
    enable_graph_permission = false
  }

  expect_failures = [var.subscription_ids]
}

run "backfill_month_count_must_be_a_whole_number" {
  command = plan

  variables {
    subscription_ids                    = ["aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"]
    create_client_secret                = false
    enable_graph_permission             = false
    billing_export_backfill_month_count = 1.5
  }

  expect_failures = [var.billing_export_backfill_month_count]
}

run "provider_tenants_must_match" {
  command = plan

  variables {
    subscription_ids        = ["aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"]
    create_client_secret    = false
    enable_graph_permission = false
  }

  override_data {
    target = data.azuread_client_config.current
    values = {
      tenant_id = "99999999-8888-7777-6666-555555555555"
    }
  }

  expect_failures = [azuread_application.spotto]
}

run "azapi_provider_tenant_must_match" {
  command = plan

  variables {
    subscription_ids        = ["aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"]
    create_client_secret    = false
    enable_graph_permission = false
  }

  override_data {
    target = data.azapi_client_config.current
    values = {
      tenant_id = "99999999-8888-7777-6666-555555555555"
    }
  }

  expect_failures = [azuread_application.spotto]
}

run "handoff_omits_more_than_fifty_sources" {
  command = plan

  variables {
    subscription_ids = [
      for index in range(25) : format("00000000-0000-0000-0000-%012d", index)
    ]
    create_client_secret           = false
    enable_graph_permission        = false
    enable_billing_exports         = true
    enable_billing_export_backfill = false
    existing_billing_export_sources = [{
      dataset_type       = "actual"
      scope_type         = "billingAccount"
      scope_path         = "/providers/Microsoft.Billing/billingAccounts/account-1"
      export_name        = "daily-actual"
      storage_account_id = "/subscriptions/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/resourceGroups/exports/providers/Microsoft.Storage/storageAccounts/existingexports"
      container_name     = "cost-exports"
      root_folder_path   = "daily/actual"
    }]
  }

  assert {
    condition     = !output.azure_manual_onboarding_billing_exports_eligible
    error_message = "Billing export handoff eligibility must be false when more than fifty sources are configured."
  }

  assert {
    condition     = !can(jsondecode(output.azure_manual_onboarding_json).billingExports)
    error_message = "Oversized billing sources must be omitted without blocking independently managed Azure resources."
  }
}

run "handoff_omits_more_than_twenty_four_kibibytes" {
  command = plan

  variables {
    subscription_ids        = ["aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"]
    create_client_secret    = false
    enable_graph_permission = false
    existing_billing_export_sources = [
      for index in range(50) : {
        dataset_type       = "actual"
        scope_type         = "billingAccount"
        scope_path         = "/providers/Microsoft.Billing/billingAccounts/account-${index}"
        export_name        = "daily-actual-${index}"
        storage_account_id = "/subscriptions/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/resourceGroups/exports/providers/Microsoft.Storage/storageAccounts/existingexports"
        container_name     = "cost-exports"
        root_folder_path   = join("", [for character_index in range(600) : "a"])
      }
    ]
  }

  assert {
    condition     = !output.azure_manual_onboarding_billing_exports_eligible
    error_message = "Billing export handoff eligibility must be false when the source payload exceeds twenty-four KiB."
  }

  assert {
    condition     = !can(jsondecode(output.azure_manual_onboarding_json).billingExports)
    error_message = "Oversized billing sources must be omitted from the portal payload without failing the Terraform plan."
  }
}

run "legacy_storage_name_is_recorded" {
  command   = apply
  state_key = "storage-migration"

  variables {
    subscription_ids                    = ["aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"]
    create_client_secret                = false
    enable_graph_permission             = false
    enable_billing_exports              = true
    enable_billing_export_backfill      = false
    billing_export_storage_account_name = "spottolegacy1234"
  }

  override_resource {
    target = azapi_resource.billing_export_resource_group[0]
    values = {
      id = "/subscriptions/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/resourceGroups/rg-spotto-cost-exports"
    }
  }

  override_resource {
    target = azapi_resource.billing_export_storage_account[0]
    values = {
      id = "/subscriptions/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/resourceGroups/rg-spotto-cost-exports/providers/Microsoft.Storage/storageAccounts/spottolegacy1234"
    }
  }

  override_resource {
    target = azapi_resource.billing_export_container[0]
    values = {
      id = "/subscriptions/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/resourceGroups/rg-spotto-cost-exports/providers/Microsoft.Storage/storageAccounts/spottolegacy1234/blobServices/default/containers/spotto-cost-exports"
    }
  }

  assert {
    condition     = azapi_resource.billing_export_storage_account[0].name == "spottolegacy1234"
    error_message = "The upgrade fixture must begin with the legacy storage account name in state."
  }
}

run "legacy_storage_name_is_not_replaced_by_new_default" {
  command   = plan
  state_key = "storage-migration"

  variables {
    subscription_ids               = ["aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"]
    create_client_secret           = false
    enable_graph_permission        = false
    enable_billing_exports         = true
    enable_billing_export_backfill = false
  }

  assert {
    condition     = azapi_resource.billing_export_storage_account[0].name == "spottolegacy1234"
    error_message = "The deterministic creation default must not rename an existing data-bearing storage account."
  }

  assert {
    condition     = jsondecode(output.azure_manual_onboarding_json).billingExports.sources[0].destination.storageAccountName == "spottolegacy1234"
    error_message = "The handoff must report the effective legacy storage name retained in state."
  }
}

run "legacy_count_based_rbac_state_is_recorded" {
  command   = apply
  state_key = "rbac-migration"

  module {
    source = "./tests/fixtures/legacy-rbac"
  }

  variables {
    management_group_scope = "/providers/Microsoft.Management/managementGroups/11111111-2222-3333-4444-555555555555"
    principal_id           = "10000000-0000-0000-0000-000000000003"
  }
}

run "legacy_count_based_rbac_state_moves_without_recreation" {
  command   = plan
  state_key = "rbac-migration"

  variables {
    assign_reader_to_all_subscriptions        = true
    create_client_secret                      = false
    enable_graph_permission                   = false
    enable_monitoring_reader                  = false
    enable_management_group_monitoring_reader = false
    enable_security_reader                    = false
    enable_key_vault_reader                   = false
    enable_reservations_reader                = false
    enable_reservations_contributor           = false
    enable_savings_plan_reader                = false
  }

  assert {
    condition     = azurerm_role_assignment.log_analytics_reader_management_group["default"].id == run.legacy_count_based_rbac_state_is_recorded.log_analytics_reader_id
    error_message = "The legacy Log Analytics Reader [0] state must move to the stable default key without recreation."
  }

  assert {
    condition     = azurerm_role_assignment.reader_management_group["default"].id == run.legacy_count_based_rbac_state_is_recorded.reader_id
    error_message = "The legacy management-group Azure Reader [0] state must move to the stable default key without recreation."
  }

  assert {
    condition     = azurerm_role_assignment.management_group_reader["default"].id == run.legacy_count_based_rbac_state_is_recorded.management_group_reader_id
    error_message = "The legacy Management Group Reader [0] state must move to the stable default key without recreation."
  }
}
