# terraform-azurerm-spotto

Terraform modules for onboarding Azure environments into Spotto.

## Modules

- `modules/onboarding`: Creates an Azure AD application/service principal, assigns read and monitoring access, grants Microsoft Graph permission to read application credentials, and optionally grants write access for Advisor/Storage Inventory actions.

## Requirements

- Terraform >= 1.3
- `hashicorp/azurerm` provider
- `Azure/azapi` provider
- `hashicorp/azuread` provider
- `hashicorp/random` provider
- `hashicorp/time` provider

## Permissions Required

- Azure AD: Application Administrator or Global Administrator to create the app and service principal.
- Azure RBAC:
  - If using `subscription_ids`, Owner or User Access Administrator on each target subscription to assign Reader, Monitoring Reader, and Log Analytics Data Reader.
  - If using `assign_reader_to_all_subscriptions = true`, Owner or User Access Administrator at tenant root scope (`/`) to assign Reader once for the whole tenant.
  - Global Administrators typically need to enable `Microsoft Entra ID > Properties > Access management for Azure resources`, then sign out and sign back in before applying the tenant root Reader assignment.
- Management Groups: Management Group Contributor or Owner if you want tenant-level assignments.
- Microsoft Graph: Admin consent to grant Application.Read.All.

## Quickstart

```hcl
module "spotto_onboarding" {
  source = "./modules/onboarding"

  subscription_ids = ["00000000-0000-0000-0000-000000000000"]
}
```

To grant Reader access across the whole tenant:

```hcl
module "spotto_onboarding" {
  source = "./modules/onboarding"

  assign_reader_to_all_subscriptions = true
}
```

When `assign_reader_to_all_subscriptions = true`, the module creates a single `Reader`
role assignment at tenant root scope (`/`). That assignment inherits to all current and
future subscriptions in the tenant. The module still enumerates currently visible
subscriptions for outputs and for any optional per-subscription custom role assignments.

If you want the apply to succeed with tenant-root RBAC only, disable the default
subscription-scoped monitoring assignments and any optional provider-scope
assignments you cannot create.

```hcl
module "spotto_onboarding" {
  source = "./modules/onboarding"

  assign_reader_to_all_subscriptions    = true
  enable_monitoring_reader              = false
  enable_log_analytics_data_reader      = false
  enable_reservations_reader            = false
  enable_savings_plan_reader            = false
}
```

By default, tenant-wide Reader mode still assigns:

- `Monitoring Reader` on each currently resolved subscription.
- `Log Analytics Data Reader` on each currently resolved subscription.
- `Reservations Reader` at `/providers/Microsoft.Capacity`.
- `Savings plan Reader` at `/providers/Microsoft.BillingBenefits`.

See `examples/onboarding-single`, `examples/onboarding-multiple`, and
`examples/onboarding-tenant-root` for complete examples.

By default, the onboarding module also assigns:

- `Monitoring Reader` on each targeted subscription for Azure Monitor and Application Insights read access.
- `Log Analytics Data Reader` on each targeted subscription for Log Analytics query and table data read access.

## Outputs

The onboarding module outputs:

- `application_client_id`
- `tenant_id`
- `client_secret` (sensitive)
- `client_secret_expiry`

## Links

- Spotto Azure onboarding docs: https://docs.spotto.ai/docs/portal/cloud-account-azure
- Spotto website: https://www.spotto.ai/

## Notes

- The client secret is stored in Terraform state. Treat state as sensitive and protect it accordingly.
- If you already have an app or custom role, import it into state instead of creating a duplicate.

## State & Backend Guidance

Use a remote backend that supports encryption and access controls (for example, Azure Storage with RBAC) because the state includes the client secret.

## Troubleshooting

- Role assignment failures right after apply may indicate Azure AD propagation delays. Re-run `terraform apply` or increase `service_principal_propagation_delay`.
- If the root-scope Reader assignment fails when `assign_reader_to_all_subscriptions = true`, ensure you have Owner or User Access Administrator at `/`. If you are a Global Administrator, enable `Access management for Azure resources` in Microsoft Entra ID, sign out, sign back in, and re-run `terraform apply`.
- If `Monitoring Reader` or `Log Analytics Data Reader` assignments fail in tenant-wide mode, you still need permission to create subscription-level RBAC assignments on the currently resolved subscriptions, or set `enable_monitoring_reader = false` and `enable_log_analytics_data_reader = false`.
- If `Reservations Reader` or `Savings plan Reader` assignments fail, ensure you can create RBAC assignments at `/providers/Microsoft.Capacity` and `/providers/Microsoft.BillingBenefits`, or disable them with `enable_reservations_reader = false` and `enable_savings_plan_reader = false`.
- If Microsoft Graph permission grants fail, ensure admin consent is allowed for Application.Read.All in your tenant.

## License

See `LICENSE`.
