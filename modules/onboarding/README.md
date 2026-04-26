# Onboarding Module

Creates the Azure AD application and service principal used by Spotto, assigns subscription and tenant-level read access for onboarding and governance collection, grants Microsoft Graph `Application.Read.All` to read applications and service principals for governance and credential posture, and optionally grants write access for Advisor/Storage Inventory actions.

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

## Notes

- The client secret is stored in Terraform state. Protect state files accordingly.
- If `client_secret_end_date` is not set, the module uses the initial apply time to set a 12-month secret expiry without rotating on every plan.
- If you already have an application or custom role, import it instead of creating a duplicate.
- The optional write-permission custom role remains per-subscription even when `assign_reader_to_all_subscriptions = true`.
- If tenant-wide Reader mode is enabled, `subscription_ids` remains a snapshot of currently resolved subscriptions used by subscription-scoped assignments and outputs.
- The module requests Microsoft Graph `Application.Read.All` for application and service principal inventory only. It does not widen to `Directory.Read.All`.
