# terraform-azurerm-spotto

Terraform modules for onboarding Azure environments into Spotto.

## Modules

- `modules/onboarding`: Creates an Azure AD application/service principal, assigns read and monitoring access, grants Microsoft Graph permission to read application credentials, and optionally grants write access for Advisor/Storage Inventory actions.

## Requirements

- Terraform >= 1.3
- `hashicorp/azurerm` provider
- `hashicorp/azuread` provider
- `hashicorp/random` provider
- `hashicorp/time` provider

## Permissions Required

- Azure AD: Application Administrator or Global Administrator to create the app and service principal.
- Azure RBAC: Owner or User Access Administrator on each subscription to assign Reader, Monitoring Reader, and Log Analytics Data Reader.
- Management Groups: Management Group Contributor or Owner if you want tenant-level assignments.
- Microsoft Graph: Admin consent to grant Application.Read.All.

## Quickstart

```hcl
module "spotto_onboarding" {
  source = "./modules/onboarding"

  subscription_ids = ["00000000-0000-0000-0000-000000000000"]
}
```

To grant Reader access to all accessible subscriptions:

```hcl
module "spotto_onboarding" {
  source = "./modules/onboarding"

  assign_reader_to_all_subscriptions = true
}
```

See `examples/onboarding-single` and `examples/onboarding-multiple` for complete examples.

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
- If Microsoft Graph permission grants fail, ensure admin consent is allowed for Application.Read.All in your tenant.

## License

See `LICENSE`.
