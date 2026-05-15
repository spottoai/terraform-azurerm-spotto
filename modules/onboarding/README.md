# Onboarding Module

Creates the Azure AD application and service principal used by Spotto, assigns subscription and tenant-level read access for onboarding and governance collection, grants Microsoft Graph `Application.Read.All` to read applications and service principals for governance and credential posture, can configure Cost Management exports to customer-owned Azure Storage, and optionally grants write access for Advisor/Storage Inventory actions.

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
  enable_log_analytics_reader      = false
  enable_management_group_reader   = false
  enable_reservations_reader       = false
  enable_savings_plan_reader       = false
}
```

By default, the module also assigns:

- `Reader` at the root management group for the tenant governance hierarchy endpoint.
- `Management Group Reader` at the root management group for management group hierarchy and tenant governance metadata.
- `Monitoring Reader` on each targeted subscription for Azure Monitor and Application Insights read access.
- `Log Analytics Reader` at the root management group when onboarding all subscriptions, otherwise on each targeted subscription, for broader workspace log analysis.
- `Reservations Reader` at `/providers/Microsoft.Capacity`.
- `Savings plan Reader` at `/providers/Microsoft.BillingBenefits`.
- Microsoft Graph `Application.Read.All` with admin consent to read applications and service principals for governance and credential posture.

Billing export setup is opt-in to avoid creating storage/export resources for existing users:

```hcl
module "spotto_onboarding" {
  source = "../../modules/onboarding"

  subscription_ids = ["00000000-0000-0000-0000-000000000000"]

  enable_billing_exports = true
}
```

When enabled, the module:

- Creates a storage account in `billing_export_resource_group_name`, or uses `billing_export_storage_account_id`. Module-created storage is created in the first targeted subscription by default; set `billing_export_storage_subscription_id` to choose a different storage host subscription. Existing storage defaults to the subscription parsed from `billing_export_storage_account_id`.
- Requests `Microsoft.CostManagement` provider registration on targeted subscriptions, plus `Microsoft.CostManagement` and `Microsoft.CostManagementExports` registration on the storage host subscription by default. It also registers `Microsoft.Storage` on the storage host subscription when creating export storage.
- Enforces storage account settings required for Spotto exports by default, including TLS 1.2, HTTPS-only traffic, public network access, Azure services bypass, and disabled anonymous blob access.
- Ensures a private blob container named `billing_export_container_name`.
- Assigns `Storage Blob Data Reader` to the Spotto service principal at the container scope.
- Creates daily `ActualCost` and `AmortizedCost` Cost Management exports for each targeted subscription.
- Creates inactive one-time backfill exports for the previous 13 closed months. Backfill run queueing is opt-in with `enable_billing_export_backfill_runs = true` because Terraform cannot observe whether Azure completed a previous imperative export run.

The PowerShell onboarding wizard can interactively discover arbitrary compatible existing recurring exports, retry `ActualCost` as `Usage`, and retry without `partitionData` when Azure rejects those settings. Terraform keeps those decisions explicit: import existing export resources if you want Terraform to manage them, remove `AmortizedCost` from `billing_export_dataset_types` if that dataset is unsupported, set `billing_export_actual_cost_definition_type = "Usage"` if the scope does not support `ActualCost`, and set `billing_export_partition_data = false` if the scope does not support partitioned export data.

## Permissions Required

- Azure AD: Application Administrator or Global Administrator to create the app and service principal.
- Azure RBAC:
  - Reader on each target subscription when using `subscription_ids`, or Reader once at tenant root scope (`/`) when using `assign_reader_to_all_subscriptions = true`.
  - Reader at the root management group for tenant governance hierarchy access.
  - Management Group Reader at the root management group for management group hierarchy visibility and tenant governance metadata coverage.
  - Reservations Reader at `/providers/Microsoft.Capacity`.
  - Savings plan Reader at `/providers/Microsoft.BillingBenefits`.
  - Monitoring Reader and Log Analytics Reader are optional but recommended for Azure Monitor, Application Insights, and broader Log Analytics coverage.
  - Global Administrators typically need to enable `Microsoft Entra ID > Properties > Access management for Azure resources`, then sign out and sign back in before applying the tenant root Reader assignment.
- Management Groups: Management Group Contributor or Owner if you want to create the root management group assignment through the module.
- Microsoft Graph: Admin consent to grant `Application.Read.All` so Spotto can read applications and service principals for governance and credential posture. This module does not require `Directory.Read.All`.
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

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `assign_reader_to_all_subscriptions` | Whether to grant Reader once at tenant root scope (`/`) so it inherits to all current and future subscriptions. | `bool` | `false` | no |
| `subscription_ids` | List of subscription IDs to grant Reader access. Ignored when `assign_reader_to_all_subscriptions` is `true`. | `list(string)` | `[]` | no |
| `app_name` | Display name for the Azure AD application. | `string` | `"Spotto AI"` | no |
| `custom_role_name` | Name for the optional custom role used for write permissions. | `string` | `"Spotto Access"` | no |
| `grant_optional_write_permissions` | Whether to create and assign the optional custom role. | `bool` | `false` | no |
| `tenant_id` | Optional tenant ID override. Defaults to the current client tenant. | `string` | `null` | no |
| `root_management_group_id` | Optional management group ID for tenant-level role assignments. Defaults to tenant ID. | `string` | `null` | no |
| `create_client_secret` | Whether to create a new client secret for the application. | `bool` | `true` | no |
| `client_secret_end_date` | Optional RFC3339 timestamp to set the client secret expiration. Defaults to 12 months from creation. | `string` | `null` | no |
| `enable_management_group_reader` | Whether to assign Management Group Reader at the root management group. | `bool` | `true` | no |
| `enable_reservations_reader` | Whether to assign Reservations Reader at `/providers/Microsoft.Capacity`. | `bool` | `true` | no |
| `enable_savings_plan_reader` | Whether to assign Savings plan Reader at `/providers/Microsoft.BillingBenefits`. | `bool` | `true` | no |
| `enable_monitoring_reader` | Whether to assign Monitoring Reader on each targeted subscription. | `bool` | `true` | no |
| `enable_log_analytics_reader` | Whether to assign Log Analytics Reader. When `assign_reader_to_all_subscriptions` is `true`, the module assigns it once at the root management group for tenant-wide workspace log access; otherwise it assigns it on each targeted subscription. | `bool` | `true` | no |
| `enable_log_analytics_data_reader` | Deprecated alias for `enable_log_analytics_reader`. When set, this value overrides the new variable. | `bool` | `null` | no |
| `enable_graph_permission` | Whether to grant Microsoft Graph `Application.Read.All` with admin consent so Spotto can read applications and service principals for governance and credential posture. | `bool` | `true` | no |
| `enable_billing_exports` | Whether to configure Cost Management billing exports to Azure Storage for the targeted subscriptions. | `bool` | `false` | no |
| `create_billing_export_storage_account` | Whether to create a storage account for billing exports. When false, `billing_export_storage_account_id` must be provided if billing exports are enabled. | `bool` | `true` | no |
| `billing_export_storage_account_id` | Existing storage account resource ID to use for billing exports when `create_billing_export_storage_account` is false. | `string` | `null` | no |
| `manage_billing_export_storage_account_settings` | Whether to enforce billing export storage account settings such as TLS 1.2, HTTPS-only traffic, public network access, Azure services bypass, and disabled anonymous blob access. | `bool` | `true` | no |
| `billing_export_storage_subscription_id` | Subscription ID for the billing export storage host. Defaults to the first targeted subscription when creating storage, or the subscription parsed from `billing_export_storage_account_id` when using existing storage. | `string` | `null` | no |
| `enable_billing_export_resource_provider_registration` | Whether to request `Microsoft.CostManagement` registration on targeted subscriptions; `Microsoft.CostManagement`, `Microsoft.CostManagementExports`, and optionally `Microsoft.Storage` on the storage host subscription. | `bool` | `true` | no |
| `billing_export_resource_group_name` | Resource group name for the module-created billing export storage account. | `string` | `"rg-spotto-cost-exports"` | no |
| `billing_export_location` | Azure region for the module-created billing export resource group and storage account. | `string` | `"australiaeast"` | no |
| `billing_export_storage_account_name` | Optional name for the module-created billing export storage account. Defaults to a generated Spotto-prefixed name. | `string` | `null` | no |
| `billing_export_container_name` | Blob container name for Spotto billing exports. | `string` | `"spotto-cost-exports"` | no |
| `billing_export_root_path` | Root folder path in the billing export container. | `string` | `"spotto"` | no |
| `billing_export_dataset_types` | Cost Management export datasets to create. Remove `AmortizedCost` if it is unsupported for the Azure agreement/scope. | `list(string)` | `["ActualCost", "AmortizedCost"]` | no |
| `billing_export_actual_cost_definition_type` | Definition type to use for `ActualCost` exports. Set to `Usage` for agreements/scopes where Azure does not support `ActualCost`. | `string` | `"ActualCost"` | no |
| `billing_export_partition_data` | Whether to request partitioned billing export data. Set to false for agreements/scopes where Azure does not support `partitionData`. | `bool` | `true` | no |
| `enable_billing_export_immediate_runs` | Whether to queue an immediate run for newly managed recurring billing exports. | `bool` | `true` | no |
| `enable_billing_export_backfill` | Whether to create inactive one-time billing export definitions for previous closed months. | `bool` | `true` | no |
| `billing_export_backfill_month_count` | Number of previous closed months to configure as one-time backfill exports. | `number` | `13` | no |
| `enable_billing_export_backfill_runs` | Whether to queue runs for the one-time backfill billing exports. Defaults to false because Terraform managed actions cannot detect whether Azure completed a previous one-time run. | `bool` | `false` | no |
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
| `write_permissions_enabled` | Whether the optional write permissions were enabled. |
| `custom_role_definition_id` | Role definition resource ID for the optional custom role. |
| `billing_exports_enabled` | Whether Cost Management billing exports were enabled. |
| `billing_export_storage_account_id` | Storage account resource ID used for billing exports. |
| `billing_export_storage_subscription_id` | Subscription ID used for module-created billing export storage. |
| `billing_export_container_id` | Blob container resource ID used for billing exports. |
| `billing_export_recurring_export_ids` | Cost Management recurring export resource IDs keyed by subscription ID and dataset type. |
| `billing_export_backfill_export_ids` | Cost Management backfill export resource IDs keyed by subscription ID, dataset type, and period. |

## Notes

- The client secret is stored in Terraform state. Protect state files accordingly.
- If `client_secret_end_date` is not set, the module uses the initial apply time to set a 12-month secret expiry without rotating on every plan.
- If you already have an application or custom role, import it instead of creating a duplicate.
- The optional write-permission custom role remains per-subscription even when `assign_reader_to_all_subscriptions = true`.
- If tenant-wide Reader mode is enabled, `subscription_ids` remains a snapshot of currently resolved subscriptions used by subscription-scoped assignments and outputs.
- The module requests Microsoft Graph `Application.Read.All` for application and service principal inventory only. It does not widen to `Directory.Read.All`.
- If `enable_billing_exports = true` with tenant-wide Reader mode, export resources are created for the current subscription snapshot; rerun Terraform after new subscriptions are added.
- Existing Cost Management exports with the same names should be imported into Terraform state before apply. The module does not interactively adopt arbitrary exports.
- Billing export storage is configured with TLS 1.2, HTTPS-only traffic, anonymous blob access disabled, public network access enabled, and Azure services network bypass when `manage_billing_export_storage_account_settings = true`.
- If your organization manages provider registration outside Terraform, set `enable_billing_export_resource_provider_registration = false` and register `Microsoft.CostManagement` before applying billing exports.
