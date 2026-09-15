# Onboarding Module

Creates the Azure AD application and service principal used by Spotto, assigns subscription and tenant-level read access for onboarding and governance collection, grants Microsoft Graph application permissions for application inventory, tenant policy, subscribed licensing, Entra admin role, PIM, group membership, user profile, and audit log visibility, can configure Cost Management exports to customer-owned Azure Storage, and separately opts into write access for Advisor/Storage Inventory actions or Azure Policy exemptions.

## Spotto Links

- Spotto website: https://www.spotto.ai/
- Spotto Azure onboarding docs: https://docs.spotto.ai/docs/portal/cloud-account-azure

## Usage

```hcl
module "spotto_onboarding" {
  source = "../../modules/onboarding"

  subscription_ids = ["00000000-0000-0000-0000-000000000000"]
}
```

To grant Reader access across the whole tenant:

```hcl
module "spotto_onboarding" {
  source = "../../modules/onboarding"

  assign_reader_to_all_subscriptions = true
}
```

When `assign_reader_to_all_subscriptions = true`, the module creates a single `Reader`
role assignment at tenant root scope (`/`) so it inherits to all current and future
subscriptions in the tenant. The module still enumerates currently visible subscriptions
for outputs and for any optional per-subscription custom role assignments.

If you want the apply to succeed with tenant-root RBAC only, disable the remaining
subscription-scoped and provider-scoped assignments, and disable management-group-scoped
roles if you cannot create them:

```hcl
module "spotto_onboarding" {
  source = "../../modules/onboarding"

  assign_reader_to_all_subscriptions = true
  enable_monitoring_reader         = false
  enable_management_group_monitoring_reader = false
  enable_security_reader          = false
  enable_key_vault_reader          = false
  enable_log_analytics_reader      = false
  enable_management_group_reader   = false
  enable_reservations_reader       = false
  enable_reservations_contributor  = false
  enable_savings_plan_reader       = false
}
```

By default, the module also assigns:

- `Management Group Reader` at the root management group for hierarchy and authorization metadata. Targeted subscription mode does not grant inherited Azure Reader there unless explicit `management_group_ids` are supplied.
- `Monitoring Reader` on each targeted subscription for Azure Monitor and Application Insights read access.
- `Monitoring Reader` on tenant-wide or explicitly selected management groups.
- `Security Reader` on each targeted subscription for Defender for Cloud assessments, secure score, and security posture.
- `Log Analytics Reader` at the root management group when onboarding all subscriptions, otherwise on each targeted subscription, for broader workspace log analysis.
- `Key Vault Reader` at the tenant-root management group in tenant-wide mode, and on every selected subscription otherwise. Explicit child management groups receive an additional assignment because Terraform cannot prove subscription ancestry.
- `Reservations Reader` at `/providers/Microsoft.Capacity`.
- Optional `Reservations Contributor` at `/providers/Microsoft.Capacity` when explicitly enabled.
- `Savings plan Reader` at `/providers/Microsoft.BillingBenefits`.
- Microsoft Graph application permissions with admin consent:
  - `Application.Read.All`
  - `RoleAssignmentSchedule.Read.Directory`
  - `RoleEligibilitySchedule.Read.Directory`
  - `RoleManagement.Read.Directory`
  - `GroupMember.Read.All`
  - `User.Read.All`
  - `AuditLog.Read.All`
  - `Policy.Read.All`
  - `LicenseAssignment.Read.All`

Billing export setup is opt-in to avoid creating storage/export resources for existing users:

```hcl
module "spotto_onboarding" {
  source = "../../modules/onboarding"

  subscription_ids = ["00000000-0000-0000-0000-000000000000"]

  enable_billing_exports = true
}
```

When enabled, the module:

- Creates a deterministically named storage account with Spotto ownership tags in `billing_export_resource_group_name`, or uses `billing_export_storage_account_id`. Name and tag drift are ignored after creation so upgrades cannot replace the account or remove Azure Policy/customer tags. Module-created storage is created in the first targeted subscription by default; set `billing_export_storage_subscription_id` to choose a different storage host subscription. Existing storage defaults to the subscription parsed from `billing_export_storage_account_id`.
- Requests `Microsoft.CostManagement` provider registration on targeted subscriptions, plus `Microsoft.CostManagement` and `Microsoft.CostManagementExports` registration on the storage host subscription by default. It also registers `Microsoft.Storage` on the storage host subscription when creating export storage.
- Enforces export-compatible settings on module-created storage. Existing storage is not mutated unless `allow_existing_billing_export_storage_network_changes = true`; that explicit opt-in enables public access, sets network default Allow, and clears existing rules.
- Ensures a private blob container named `billing_export_container_name`.
- Assigns `Storage Blob Data Reader` to the Spotto service principal at the container scope.
- Creates daily `ActualCost` and `AmortizedCost` Cost Management exports for each targeted subscription.
- Creates an EA `Usage` daily export at every explicit `billing_export_management_group_ids` target while retaining subscription exports as the completeness fallback.
- Creates inactive one-time backfill exports for the previous 13 closed months. Backfill run queueing is opt-in with `enable_billing_export_backfill_runs = true` because Terraform cannot observe whether Azure completed a previous imperative export run.

The PowerShell onboarding wizard can interactively discover arbitrary compatible existing recurring exports, retry `ActualCost` as `Usage`, and retry without `partitionData` when Azure rejects those settings. Terraform keeps those decisions explicit: use `existing_billing_export_sources` to reuse and hand off unmanaged exports, import existing export resources if Terraform should manage them, remove `AmortizedCost` from `billing_export_dataset_types` if that dataset is unsupported, set `billing_export_actual_cost_definition_type = "Usage"` if the scope does not support `ActualCost`, and set `billing_export_partition_data = false` if the scope does not support partitioned export data. Terraform does not verify that a declared existing destination belongs to the named export; only set `grant_existing_billing_export_storage_reader = true` after checking every locator against Azure.

`azapi_resource_action` executes on every apply. Immediate recurring and backfill runs therefore default to false. Enable the relevant run toggle for one apply only, then return it to false.

For an explicit management-group Usage export and an existing billing-profile export:

```hcl
module "spotto_onboarding" {
  source = "../../modules/onboarding"

  subscription_ids      = ["00000000-0000-0000-0000-000000000000"]
  management_group_ids  = ["landing-zone"]
  enable_billing_exports = true

  billing_export_management_group_ids = ["landing-zone"]

  # Explicit authorization after verifying the destination below in Azure.
  grant_existing_billing_export_storage_reader = true

  existing_billing_export_sources = [{
    dataset_type       = "actual"
    scope_type         = "billingProfile"
    scope_path         = "/providers/Microsoft.Billing/billingAccounts/account-id/billingProfiles/profile-id"
    export_name        = "daily-actual"
    storage_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/exports/providers/Microsoft.Storage/storageAccounts/existingexports"
    container_name     = "cost-exports"
    root_folder_path   = "daily/actual"
  }]
}
```

The sensitive `azure_manual_onboarding_json` output uses the same versioned contract as the
PowerShell wizard. Retrieve it only into a protected destination and remove local copies after
the portal import is complete.

Azure Policy exemption writes are a separate opt-in and do not change the existing Advisor/Storage choice:

```hcl
module "spotto_onboarding" {
  source = "../../modules/onboarding"

  subscription_ids                     = ["00000000-0000-0000-0000-000000000000"]
  grant_policy_exemption_permissions   = true
  policy_assignment_exempt_scopes = [
    "/providers/Microsoft.Management/managementGroups/production"
  ]
}
```

The subscription role receives only `Microsoft.Authorization/policyExemptions/write` and
`Microsoft.Authorization/policyAssignments/exempt/action`. The management-group list is
optional and explicit; use it only for scopes where initiatives are inherited. Azure permits
only one management group in a custom role's assignable scopes, so the module creates one
deterministic role per selected scope. Each role contains `policyAssignments/exempt/action`
only. This module does not grant policy
assignment, definition, remediation, exemption-delete, or tenant-root write access.

## Permissions Required

- Azure AD: Application Administrator or Global Administrator to create the app and service principal.
- Azure RBAC:
  - Reader on each target subscription when using `subscription_ids`, or Reader once at tenant root scope (`/`) when using `assign_reader_to_all_subscriptions = true`.
  - Reader at explicitly selected management groups or in tenant-wide onboarding; targeted subscription defaults do not grant inherited management-group Reader access.
  - Management Group Reader at the root management group for management group hierarchy visibility and tenant governance metadata coverage.
  - Reservations Reader at `/providers/Microsoft.Capacity`.
  - Reservations Contributor at `/providers/Microsoft.Capacity` only when explicitly enabled for reservation refund quotes and management workflows.
  - Savings plan Reader at `/providers/Microsoft.BillingBenefits`.
  - Monitoring Reader, Log Analytics Reader, and Security Reader are enabled by default for Azure Monitor, Application Insights, broader Log Analytics, and Defender for Cloud posture coverage.
  - Optional `Microsoft.Security` resource provider registration requires `Microsoft.Resources/subscriptions/providers/register/action` on every targeted subscription. Contributor and Owner include this action.
  - Policy exemption setup, when enabled, requires `Microsoft.Authorization/roleDefinitions/write` and `Microsoft.Authorization/roleAssignments/write` at every targeted subscription and every management group listed in `policy_assignment_exempt_scopes`. Owner or User Access Administrator provides both at the relevant scope; Role Based Access Control Administrator alone is insufficient because it cannot create custom role definitions.
  - Global Administrators typically need to enable `Microsoft Entra ID > Properties > Access management for Azure resources`, then sign out and sign back in before applying the tenant root Reader assignment.
- Management Groups: creating root-management-group role assignments requires `Microsoft.Authorization/roleAssignments/write` there, such as Owner, User Access Administrator, or Role Based Access Control Administrator. Management Group Contributor alone cannot assign Azure RBAC access.
- Microsoft Graph: Admin consent to grant application permissions for application inventory, tenant policy, subscribed licensing, Entra Global Admin/PIM visibility, group membership, user profile, and audit log visibility. This module does not require `Directory.Read.All`.
- Cost Management exports: Permission to create/update `Microsoft.CostManagement/exports` on each targeted subscription when `enable_billing_exports = true`.
- Billing export storage: Permission to create or use the selected storage account/container and assign `Storage Blob Data Reader` at the container scope when `enable_billing_exports = true`.

## Provider Setup

```hcl
provider "azurerm" {
  features {}
}

provider "azapi" {}

provider "azuread" {}
```

Set `enable_security_resource_provider_registration = true` to request `Microsoft.Security` registration on every targeted subscription. Terraform resource actions cannot suppress Azure authorization failures, so this is disabled by default and requires `Microsoft.Resources/subscriptions/providers/register/action` on every target.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `assign_reader_to_all_subscriptions` | Whether to grant Reader once at tenant root scope (`/`) so it inherits to all current and future subscriptions. | `bool` | `false` | no |
| `subscription_ids` | List of subscription IDs to grant Reader access. Ignored when `assign_reader_to_all_subscriptions` is `true`. | `list(string)` | `[]` | no |
| `app_name` | Display name for the Azure AD application. | `string` | `"Spotto"` | no |
| `custom_role_name` | Name for the optional custom role used for write permissions. | `string` | `"Spotto Access"` | no |
| `grant_optional_write_permissions` | Whether to create and assign the optional custom role. | `bool` | `false` | no |
| `grant_policy_exemption_permissions` | Whether to add least-privilege policy exemption actions at targeted subscriptions. | `bool` | `false` | no |
| `policy_assignment_exempt_scopes` | Explicit management-group resource IDs for inherited policy assignments. | `set(string)` | `[]` | no |
| `policy_assignment_exempt_role_name` | Base name of each action-only management-group custom role. | `string` | `"Spotto Policy Assignment Exempt"` | no |
| `tenant_id` | Optional tenant assertion. The effective tenant must equal the AzureRM, AzureAD, and AzAPI provider tenants. | `string` | `null` | no |
| `root_management_group_id` | Optional management group ID for tenant-level role assignments. Defaults to tenant ID. | `string` | `null` | no |
| `management_group_ids` | Explicit management group IDs for governance roles. Defaults to the root management group when empty. | `set(string)` | `[]` | no |
| `create_client_secret` | Whether to create a new client secret for the application. | `bool` | `true` | no |
| `client_secret_end_date` | Optional RFC3339 timestamp to set the client secret expiration. Defaults to 12 months from creation. | `string` | `null` | no |
| `enable_management_group_reader` | Whether to assign Management Group Reader for hierarchy/authorization metadata, plus Azure Reader in tenant-wide or explicitly selected management-group mode. | `bool` | `true` | no |
| `enable_management_group_monitoring_reader` | Whether to assign Monitoring Reader on tenant-wide or explicit management-group scopes. | `bool` | `true` | no |
| `enable_key_vault_reader` | Whether to assign Key Vault Reader at covered management groups or targeted subscription fallback scopes. | `bool` | `true` | no |
| `enable_reservations_reader` | Whether to assign Reservations Reader at `/providers/Microsoft.Capacity`. | `bool` | `true` | no |
| `enable_reservations_contributor` | Whether to assign Reservations Contributor at `/providers/Microsoft.Capacity` for reservation refund quotes and management workflows. | `bool` | `false` | no |
| `enable_savings_plan_reader` | Whether to assign Savings plan Reader at `/providers/Microsoft.BillingBenefits`. | `bool` | `true` | no |
| `enable_monitoring_reader` | Whether to assign Monitoring Reader on each targeted subscription. | `bool` | `true` | no |
| `enable_security_reader` | Whether to assign Security Reader on each targeted subscription for Defender for Cloud assessments and security posture. | `bool` | `true` | no |
| `enable_security_resource_provider_registration` | Whether to request `Microsoft.Security` registration on each targeted subscription. Azure authorization failures fail the apply, so enable this only for an identity with provider-registration permission. | `bool` | `false` | no |
| `enable_log_analytics_reader` | Whether to assign Log Analytics Reader at tenant-wide/explicit management groups and targeted subscriptions as applicable. | `bool` | `true` | no |
| `enable_log_analytics_data_reader` | Deprecated alias for `enable_log_analytics_reader`. When set, this value overrides the new variable. | `bool` | `null` | no |
| `enable_graph_permission` | Whether to grant Microsoft Graph application permissions for application inventory, tenant policy, subscribed licensing, Entra admin role, PIM, group membership, user profile, and audit log visibility. | `bool` | `true` | no |
| `enable_billing_exports` | Whether to configure Cost Management billing exports to Azure Storage for the targeted subscriptions. | `bool` | `false` | no |
| `create_billing_export_storage_account` | Whether to create a storage account for billing exports. When false, `billing_export_storage_account_id` must be provided if billing exports are enabled. | `bool` | `true` | no |
| `billing_export_storage_account_id` | Existing storage account resource ID to use for billing exports when `create_billing_export_storage_account` is false. | `string` | `null` | no |
| `manage_billing_export_storage_account_settings` | Whether to enforce billing export storage account settings such as TLS 1.2, HTTPS-only traffic, public network access, Azure services bypass, and disabled anonymous blob access. | `bool` | `true` | no |
| `allow_existing_billing_export_storage_network_changes` | Whether Terraform may enable public/default-Allow access and clear network rules on existing billing export storage. | `bool` | `false` | no |
| `billing_export_storage_subscription_id` | Subscription ID for the billing export storage host. Defaults to the first targeted subscription when creating storage, or the subscription parsed from `billing_export_storage_account_id` when using existing storage. | `string` | `null` | no |
| `enable_billing_export_resource_provider_registration` | Whether to request `Microsoft.CostManagement` registration on targeted subscriptions; `Microsoft.CostManagement`, `Microsoft.CostManagementExports`, and optionally `Microsoft.Storage` on the storage host subscription. | `bool` | `true` | no |
| `billing_export_resource_group_name` | Resource group name for the module-created billing export storage account. | `string` | `"rg-spotto-cost-exports"` | no |
| `billing_export_location` | Azure region for the module-created billing export resource group and storage account. | `string` | `"australiaeast"` | no |
| `billing_export_storage_account_name` | Optional creation-time name for module-created export storage. New storage defaults to `billingexports` plus the final ten normalized tenant-ID characters; existing state retains its recorded name. | `string` | `null` | no |
| `billing_export_container_name` | Blob container name for Spotto billing exports. | `string` | `"spotto-cost-exports"` | no |
| `billing_export_root_path` | Root folder path in the billing export container. | `string` | `"spotto"` | no |
| `billing_export_dataset_types` | Cost Management export datasets to create. Remove `AmortizedCost` if it is unsupported for the Azure agreement/scope. | `list(string)` | `["ActualCost", "AmortizedCost"]` | no |
| `billing_export_management_group_ids` | Explicit management groups where EA Usage daily exports should be created. | `set(string)` | `[]` | no |
| `grant_existing_billing_export_storage_reader` | Whether to grant Blob Data Reader for explicitly declared existing source destinations after operator verification. | `bool` | `false` | no |
| `existing_billing_export_sources` | Explicit unmanaged recurring exports to include in the portal handoff. | `list(object)` | `[]` | no |
| `billing_export_actual_cost_definition_type` | Definition type to use for `ActualCost` exports. Set to `Usage` for agreements/scopes where Azure does not support `ActualCost`. | `string` | `"ActualCost"` | no |
| `billing_export_partition_data` | Whether to request partitioned billing export data. Set to false for agreements/scopes where Azure does not support `partitionData`. | `bool` | `true` | no |
| `enable_billing_export_immediate_runs` | Whether to queue recurring runs during apply. Enable for one apply only because AzAPI repeats actions. | `bool` | `false` | no |
| `enable_billing_export_backfill` | Whether to create inactive one-time billing export definitions for previous closed months. | `bool` | `true` | no |
| `billing_export_backfill_month_count` | Number of previous closed months to configure as one-time backfill exports. | `number` | `13` | no |
| `enable_billing_export_backfill_runs` | Whether to queue backfill runs during apply. Enable for one apply only because AzAPI repeats actions. | `bool` | `false` | no |
| `service_principal_propagation_delay` | Delay to allow the service principal to propagate before role assignments. Use `"0s"` to disable. | `string` | `"30s"` | no |
| `custom_role_propagation_delay` | Delay to allow the custom role definition to propagate before assignments. Use `"0s"` to disable. | `string` | `"10s"` | no |

## Outputs

| Name | Description |
|------|-------------|
| `application_client_id` | Application (client) ID for the Spotto service principal. |
| `application_object_id` | Object ID of the Azure AD application. |
| `service_principal_object_id` | Object ID of the Azure AD service principal. |
| `tenant_id` | Tenant ID used for the deployment. |
| `client_secret` | Client secret for the application (sensitive). |
| `client_secret_expiry` | Expiration timestamp for the client secret. |
| `subscription_ids` | Subscription IDs resolved for the deployment. In tenant-wide Reader mode, this is the current subscription snapshot, not a limit on inherited root-scope access. |
| `management_group_ids` | Management group IDs used for governance assignments. |
| `write_permissions_enabled` | Whether the optional write permissions were enabled. |
| `custom_role_definition_id` | Role definition resource ID for the optional custom role. |
| `policy_exemption_permissions_enabled` | Whether subscription-scoped policy exemption permissions were enabled. |
| `policy_assignment_exempt_scopes` | Explicit management-group scopes granted the assignment exempt action. |
| `policy_assignment_exempt_role_definition_ids` | Role definition IDs keyed by explicit management-group scope. Azure receives one action-only custom role per scope. |
| `billing_exports_enabled` | Whether Cost Management billing exports were enabled. |
| `billing_export_storage_account_id` | Storage account resource ID used for billing exports. |
| `billing_export_storage_subscription_id` | Subscription ID used for module-created billing export storage. |
| `billing_export_container_id` | Blob container resource ID used for billing exports. |
| `billing_export_recurring_export_ids` | Cost Management recurring export resource IDs keyed by subscription ID and dataset type. |
| `billing_export_backfill_export_ids` | Cost Management backfill export resource IDs keyed by subscription ID, dataset type, and calendar period (`YYYYMM`), preserving the legacy output contract. |
| `billing_export_backfill_export_stable_ids` | Cost Management backfill export resource IDs keyed by subscription ID, dataset type, and stable months-ago period. |
| `billing_export_management_group_export_ids` | Cost Management Usage export resource IDs keyed by management group ID. |
| `azure_manual_onboarding_json` | Sensitive schema-versioned JSON accepted by the Spotto portal manual-onboarding flow. |
| `azure_manual_onboarding_billing_exports_eligible` | Whether all configured billing sources fit the portal handoff's 50-source and 24-KiB limits. |

## Notes

- The client secret is stored in Terraform state. Protect state files accordingly.
- If `client_secret_end_date` is not set, the module uses the initial apply time to set a 12-month secret expiry without rotating on every plan.
- If you already have an application or custom role, import it instead of creating a duplicate.
- New applications carry the `SpottoAzureOnboarding` and tenant ownership tags used by the PowerShell flow.
- Existing module-created billing storage keeps its state-recorded name. `billing_export_storage_account_name` is creation-time only; intentionally renaming storage requires an explicit state migration or replacement workflow.
- If the deterministic name is unavailable globally, set an available `billing_export_storage_account_name` explicitly and plan again.
- Removing the legacy `azapi_update_resource` entry for existing storage is state-only and does not restore firewall rules previously overwritten by older module versions. Review the live account and restore its intended network perimeter explicitly.
- Backfill resources now use plan-known `months-ago-NN` keys. Before applying an upgrade with existing calendar-keyed backfill state, move/import those entries to the new addresses or accept recreation of the inactive definitions. Map the most recent previous closed month to `months-ago-01`, then `months-ago-02`, and so on; for example: `terraform state mv 'module.spotto.azapi_resource.billing_export_backfill[\"<subscription>|ActualCost|202607\"]' 'module.spotto.azapi_resource.billing_export_backfill[\"<subscription>|ActualCost|months-ago-01\"]'`. Existing billing blobs are not deleted by recreating definitions.
- Existing deployments that need to retain Reservations Contributor must set `enable_reservations_contributor = true` before upgrading; otherwise the new Recommended default removes that assignment.
- Billing sources are omitted from `azure_manual_onboarding_json` when the complete set exceeds 50 sources or 24 KiB. Check `azure_manual_onboarding_billing_exports_eligible`; Azure export resources remain independently manageable when it is false.
- Backfill graph size is `subscription count × dataset count × month count`, with the same number of optional run actions. Stage large estates by reducing one or more of those inputs.
- The module moves the three legacy `[0]` management-group role assignment addresses to the stable `"default"` key. Targeted subscription upgrades intentionally remove broad Azure Reader at tenant-root while preserving Management Group Reader hierarchy visibility.
- The optional write-permission custom role remains per-subscription even when `assign_reader_to_all_subscriptions = true`.
- Policy exemption permissions remain disabled unless `grant_policy_exemption_permissions = true`; clearing the flag and management-group scope set removes only module-owned permission assignments, not existing Azure exemptions.
- If tenant-wide Reader mode is enabled, `subscription_ids` remains a snapshot of currently resolved subscriptions used by subscription-scoped assignments and outputs.
- The module requests the Microsoft Graph application permissions listed above for application inventory, tenant policy, subscribed licensing, Entra Global Admin/PIM visibility, group membership, user profile, and audit log visibility. It does not widen to `Directory.Read.All`.
- If `enable_billing_exports = true` with tenant-wide Reader mode, export resources are created for the current subscription snapshot; rerun Terraform after new subscriptions are added.
- Existing Cost Management exports with the same Terraform-managed names should be imported before apply. Use `existing_billing_export_sources` for explicit read-only reuse without managing the export definition or changing its storage network settings. Existing-destination Blob Data Reader is separately opt-in.
- Terraform cannot automatically retry a failed tenant-root assignment at subscriptions in the same apply. Use explicit `management_group_ids` and/or `subscription_ids` when root authorization is unavailable.
- The `azure_manual_onboarding_json` output can contain the generated client secret and is intentionally sensitive. Protect both the output and Terraform state.
- Module-created billing export storage is configured with TLS 1.2, HTTPS-only traffic, anonymous blob access disabled, public network access enabled, and Azure services network bypass. Existing storage is mutated only when both `manage_billing_export_storage_account_settings` and `allow_existing_billing_export_storage_network_changes` are true.
- Provider registration uses imperative POST actions. After bootstrap, set `enable_billing_export_resource_provider_registration = false` to avoid repeating them on later applies; disable it from the outset when your organization registers the required namespaces centrally.
