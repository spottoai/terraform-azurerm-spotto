# Onboarding Module

Creates the Azure AD application and service principal used by Spotto, assigns read and monitoring access to subscriptions, grants Microsoft Graph permission to read application credentials, and optionally grants write access for Advisor/Storage Inventory actions.

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

To grant Reader access to all accessible subscriptions:

```hcl
module "spotto_onboarding" {
  source = "../../modules/onboarding"

  assign_reader_to_all_subscriptions = true
}
```

By default, the module also assigns:

- `Monitoring Reader` on each targeted subscription for Azure Monitor and Application Insights read access.
- `Log Analytics Data Reader` on each targeted subscription for Log Analytics query and table data read access.

## Permissions Required

- Azure AD: Application Administrator or Global Administrator to create the app and service principal.
- Azure RBAC: Owner or User Access Administrator on each subscription to assign Reader, Monitoring Reader, and Log Analytics Data Reader.
- Management Groups: Management Group Contributor or Owner if you want tenant-level assignments.
- Microsoft Graph: Admin consent to grant Application.Read.All.

## Provider Setup

```hcl
provider "azurerm" {
  features {}
}

provider "azuread" {}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `assign_reader_to_all_subscriptions` | Whether to grant Reader access to all accessible subscriptions. | `bool` | `false` | no |
| `subscription_ids` | List of subscription IDs to grant Reader access. Ignored when `assign_reader_to_all_subscriptions` is `true`. | `list(string)` | `[]` | no |
| `app_name` | Display name for the Azure AD application. | `string` | `"Spotto AI"` | no |
| `custom_role_name` | Name for the optional custom role used for write permissions. | `string` | `"Spotto Access"` | no |
| `grant_optional_write_permissions` | Whether to create and assign the optional custom role. | `bool` | `false` | no |
| `tenant_id` | Optional tenant ID override. Defaults to the current client tenant. | `string` | `null` | no |
| `root_management_group_id` | Optional management group ID for tenant-level role assignments. Defaults to tenant ID. | `string` | `null` | no |
| `create_client_secret` | Whether to create a new client secret for the application. | `bool` | `true` | no |
| `client_secret_end_date` | Optional RFC3339 timestamp to set the client secret expiration. Defaults to 12 months from creation. | `string` | `null` | no |
| `enable_management_group_reader` | Whether to assign Management Group Reader at the root management group. | `bool` | `true` | no |
| `enable_reservations_reader` | Whether to assign Reservations Reader at the tenant level. | `bool` | `true` | no |
| `enable_savings_plan_reader` | Whether to assign Savings Plan Reader at the tenant level. | `bool` | `true` | no |
| `enable_monitoring_reader` | Whether to assign Monitoring Reader on each targeted subscription. | `bool` | `true` | no |
| `enable_log_analytics_data_reader` | Whether to assign Log Analytics Data Reader on each targeted subscription. | `bool` | `true` | no |
| `enable_graph_permission` | Whether to grant Microsoft Graph Application.Read.All permission. | `bool` | `true` | no |
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
| `subscription_ids` | Subscription IDs targeted for Reader access. |
| `write_permissions_enabled` | Whether the optional write permissions were enabled. |
| `custom_role_definition_id` | Role definition resource ID for the optional custom role. |

## Notes

- The client secret is stored in Terraform state. Protect state files accordingly.
- If `client_secret_end_date` is not set, the module uses the initial apply time to set a 12-month secret expiry without rotating on every plan.
- If you already have an application or custom role, import it instead of creating a duplicate.
