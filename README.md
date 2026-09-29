# terraform-azurerm-spotto

Terraform modules for onboarding Azure environments into Spotto.

## Modules

- `modules/onboarding`: Creates an Azure AD application/service principal, assigns subscription and tenant-level read access for Spotto onboarding and governance collection, grants Microsoft Graph application permissions for application inventory, tenant policy, subscribed licensing, Entra admin role, PIM, group membership, user profile, and audit log visibility, can configure Cost Management exports to Azure Storage, optionally assigns Log Analytics Reader for broader workspace analysis, and separately opts into write access for Advisor/Storage Inventory actions or Azure Policy exemptions.

## Requirements

- Terraform >= 1.12.0
- `hashicorp/azurerm` provider
- `Azure/azapi` provider
- `hashicorp/azuread` provider
- `hashicorp/random` provider
- `hashicorp/time` provider

## Permissions Required

- Azure AD: Application Administrator or Global Administrator to create the app and service principal.
- Azure RBAC:
  - Reader on each target subscription when using `subscription_ids`, or Reader once at tenant root scope (`/`) when using `assign_reader_to_all_subscriptions = true`.
  - Management Group Reader at the root management group for management group hierarchy visibility and tenant governance metadata coverage.
  - Reservations Reader at `/providers/Microsoft.Capacity`.
  - Optional Reservations Contributor at `/providers/Microsoft.Capacity` for reservation refund quotes and management workflows.
  - Savings plan Reader at `/providers/Microsoft.BillingBenefits`.
  - Monitoring Reader, Log Analytics Reader, Security Reader, and Key Vault Reader are enabled by default for Azure Monitor, Application Insights, Log Analytics, Defender for Cloud posture, and vault expiry metadata.
  - Optional `Microsoft.Security` resource provider registration requires `Microsoft.Resources/subscriptions/providers/register/action` on every targeted subscription. Contributor and Owner include this action.
  - Cost Management export setup, when enabled, requires permission to create/update `Microsoft.CostManagement/exports` on each targeted subscription.
  - Billing export storage setup, when enabled, requires permission to create or use the target storage account/container and assign `Storage Blob Data Reader` at the container scope.
  - Policy exemption setup, when enabled, requires `Microsoft.Authorization/roleDefinitions/write` and `Microsoft.Authorization/roleAssignments/write` at every targeted subscription and every management group listed in `policy_assignment_exempt_scopes`. Owner or User Access Administrator provides both at the relevant scope; Role Based Access Control Administrator alone is insufficient because it cannot create custom role definitions.
  - Global Administrators typically need to enable `Microsoft Entra ID > Properties > Access management for Azure resources`, then sign out and sign back in before applying the tenant root Reader assignment.
- Management Groups: creating root-management-group role assignments requires `Microsoft.Authorization/roleAssignments/write` there, such as Owner, User Access Administrator, or Role Based Access Control Administrator. Management Group Contributor alone cannot assign Azure RBAC access.
- Microsoft Graph: Admin consent to grant application permissions for application inventory, tenant policy, subscribed licensing, Entra Global Admin/PIM visibility, group membership, user profile, and audit log visibility. This module does not require `Directory.Read.All`.

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
subscription-scoped monitoring assignments, any management-group-scoped roles you
cannot create, and any optional provider-scope assignments you cannot create.

```hcl
module "spotto_onboarding" {
  source = "./modules/onboarding"

  assign_reader_to_all_subscriptions    = true
  enable_monitoring_reader              = false
  enable_management_group_monitoring_reader = false
  enable_security_reader                = false
  enable_key_vault_reader               = false
  enable_log_analytics_reader           = false
  enable_management_group_reader        = false
  enable_reservations_reader            = false
  enable_reservations_contributor       = false
  enable_savings_plan_reader            = false
}
```

By default, tenant-wide Reader mode still assigns:

- `Management Group Reader` at the root management group.
- `Monitoring Reader` on each currently resolved subscription.
- `Monitoring Reader` at the root management group.
- `Security Reader` on each currently resolved subscription.
- `Log Analytics Reader` at the root management group.
- `Key Vault Reader` at the root management group.
- `Reservations Reader` at `/providers/Microsoft.Capacity`.
- `Savings plan Reader` at `/providers/Microsoft.BillingBenefits`.

See `examples/onboarding-single`, `examples/onboarding-multiple`, and
`examples/onboarding-tenant-root` for complete examples.

By default, the onboarding module also assigns:

- `Management Group Reader` at the root management group for management group hierarchy and tenant governance metadata.
- `Monitoring Reader` on each targeted subscription for Azure Monitor and Application Insights read access.
- `Security Reader` on each targeted subscription for Defender for Cloud assessments, secure score, and security posture.
- `Log Analytics Reader` at the root management group when onboarding all subscriptions, otherwise on each targeted subscription, for broader workspace log analysis.
- `Key Vault Reader` at the root management group for tenant-wide onboarding, otherwise on each targeted subscription, for secret/key/certificate expiry metadata without secret values.
- `Reservations Reader` at `/providers/Microsoft.Capacity`.
- Optional `Reservations Contributor` at `/providers/Microsoft.Capacity` when `enable_reservations_contributor = true`.
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

To configure the highly recommended Cost Management exports:

```hcl
module "spotto_onboarding" {
  source = "./modules/onboarding"

  subscription_ids = ["00000000-0000-0000-0000-000000000000"]

  enable_billing_exports = true
}
```

When `enable_billing_exports = true`, the module creates or uses a customer-owned storage account, ensures a private export container, grants the Spotto service principal `Storage Blob Data Reader` on the managed container, creates daily actual/amortized Cost Management exports, and configures one-time backfill exports for the previous 13 closed months. New storage defaults to the PowerShell-compatible deterministic name `billingexports<last-10-tenant-characters>` and receives Spotto tenant/ownership tags at creation. Storage name and tag drift are ignored afterward so upgrades cannot replace the account or remove Azure Policy/customer tags. Module-created export storage is created in the first targeted subscription by default; set `billing_export_storage_subscription_id` to choose a different storage host subscription. When using existing storage, the storage host subscription and handoff account name are parsed from `billing_export_storage_account_id`. Existing storage network settings are not changed unless `allow_existing_billing_export_storage_network_changes = true`; that opt-in enables public access, sets the default network action to Allow, and clears existing network rules. The module requests the required resource provider registrations by default, including `Microsoft.CostManagement` on export target subscriptions and `Microsoft.CostManagement`/`Microsoft.CostManagementExports` on the storage host subscription; after bootstrap, set `enable_billing_export_resource_provider_registration = false` to avoid repeated registration POSTs, or disable it from the outset if your organization manages provider registration separately. If Azure does not support amortized exports for the agreement/scope, remove `AmortizedCost` from `billing_export_dataset_types`. If Azure does not support `ActualCost`, set `billing_export_actual_cost_definition_type = "Usage"`. If Azure does not support partitioned export data for the scope, set `billing_export_partition_data = false`.

Set `billing_export_management_group_ids` to create EA Usage exports at explicit management groups in addition to the subscription completeness fallback. To reuse an unmanaged billing-, management-group-, or subscription-scope recurring export without importing its definition, provide `existing_billing_export_sources`; the module includes the locator in the portal handoff without changing the export or storage. After independently verifying every declared destination, set `grant_existing_billing_export_storage_reader = true` if Terraform should grant container-level Blob Data Reader.

Terraform creates backfill definitions by default. Immediate recurring and backfill runs are opt-in because AzAPI actions execute again on subsequent applies. Enable `enable_billing_export_immediate_runs` or `enable_billing_export_backfill_runs` for one apply, then return it to `false`.

Azure Policy exemption creation is also opt-in and independent of the existing Advisor/Storage write role:

```hcl
module "spotto_onboarding" {
  source = "./modules/onboarding"

  subscription_ids                   = ["00000000-0000-0000-0000-000000000000"]
  grant_policy_exemption_permissions = true

  # Only required for initiatives inherited from these exact management groups.
  policy_assignment_exempt_scopes = [
    "/providers/Microsoft.Management/managementGroups/production"
  ]
}
```

No policy write is granted by default. See the onboarding module README for the exact two
subscription actions and the action-only inherited-assignment role created separately for
each selected management group.

## Outputs

The onboarding module outputs:

- `application_client_id`
- `tenant_id`
- `management_group_ids`
- `client_secret` (sensitive)
- `client_secret_expiry`
- `billing_export_storage_account_id`
- `billing_export_container_id`
- `billing_export_recurring_export_ids`
- `billing_export_backfill_export_ids`
- `billing_export_backfill_export_stable_ids`
- `billing_export_management_group_export_ids`
- `azure_manual_onboarding_json` (sensitive portal-import payload)
- `azure_manual_onboarding_billing_exports_eligible`
- `policy_exemption_permissions_enabled`
- `policy_assignment_exempt_scopes`
- `policy_assignment_exempt_role_definition_ids`

## Links

- Spotto Azure onboarding docs: https://docs.spotto.ai/docs/portal/cloud-account-azure
- Spotto website: https://www.spotto.ai/

## Notes

- The client secret is stored in Terraform state. Treat state as sensitive and protect it accordingly.
- If you already have an app or custom role, import it into state instead of creating a duplicate.
- Existing module-created billing storage retains its state-recorded name during upgrades. `billing_export_storage_account_name` is therefore a creation-time setting; intentionally changing it requires an explicit state migration or replacement procedure.
- If the deterministic storage name is already taken globally, set an available `billing_export_storage_account_name` explicitly and plan again.
- If an earlier module version already widened an existing storage account's network ACLs, this release removes the update-only resource from Terraform state without restoring prior Azure settings. Review and restore the account's intended firewall rules explicitly.
- Backfill instance keys now use stable `months-ago-NN` identifiers so initial plans are deterministic. Deployments with older calendar-keyed backfill state must move/import those state entries to the new keys before apply, or accept recreation of the inactive export definitions. Map the most recent previous closed month to `months-ago-01`, the next to `months-ago-02`, and so on; for example: `terraform state mv 'module.spotto.azapi_resource.billing_export_backfill[\"<subscription>|ActualCost|202607\"]' 'module.spotto.azapi_resource.billing_export_backfill[\"<subscription>|ActualCost|months-ago-01\"]'`. Stored billing blobs are not removed by that definition migration.
- Existing deployments that need to retain Reservations Contributor must set `enable_reservations_contributor = true` before upgrading; the new Recommended default removes that assignment.
- The portal handoff carries billing sources only when the complete source set fits its 50-source and 24-KiB limits. When `azure_manual_onboarding_billing_exports_eligible` is false, Azure export resources still plan normally and `azure_manual_onboarding_json` remains a valid credentials-only payload.
- Backfill creates `subscription count × dataset count × month count` definitions and can create the same number of run actions. Stage large estates by reducing the targeted subscriptions, datasets, or `billing_export_backfill_month_count`.
- The module requires the AzureRM, AzureAD, and AzAPI provider tenants and optional `tenant_id` assertion to match; cross-tenant onboarding is not supported.
- Terraform cannot automatically recover from a failed tenant-root role assignment during the same apply. Set `management_group_ids` and/or use `subscription_ids` explicitly when root access is unavailable.

Set `enable_security_resource_provider_registration = true` to request `Microsoft.Security` registration on every currently resolved subscription. Terraform resource actions cannot treat an Azure authorization failure as best effort, so this is disabled by default. Enable it only when the applying identity has `Microsoft.Resources/subscriptions/providers/register/action`; a rejected request fails the apply.

## State & Backend Guidance

Use a remote backend that supports encryption and access controls (for example, Azure Storage with RBAC) because the state includes the client secret.

## Troubleshooting

- Role assignment failures right after apply may indicate Azure AD propagation delays. Re-run `terraform apply` or increase `service_principal_propagation_delay`.
- If the root-scope Reader assignment fails when `assign_reader_to_all_subscriptions = true`, ensure you have Owner or User Access Administrator at `/`. If you are a Global Administrator, enable `Access management for Azure resources` in Microsoft Entra ID, sign out, sign back in, and re-run `terraform apply`.
- If management-group role assignment fails, provide accessible child IDs through `management_group_ids`, or disable the relevant `enable_management_group_reader`, `enable_management_group_monitoring_reader`, `enable_log_analytics_reader`, or `enable_key_vault_reader` flag.
- If `Monitoring Reader` assignments fail in tenant-wide mode, you still need permission on the currently resolved subscriptions and effective management groups, or must disable the corresponding monitoring flags.
- If `Security Reader` assignments fail, ensure you can create subscription-level RBAC assignments on the targeted subscriptions, or set `enable_security_reader = false`.
- If `Microsoft.Security` registration fails, grant the applying identity `Microsoft.Resources/subscriptions/providers/register/action` on every targeted subscription, or leave `enable_security_resource_provider_registration = false` and register the provider through another onboarding path.
- If `Log Analytics Reader` assignment fails in tenant-wide mode, ensure you can create RBAC assignments on the root management group, or set `enable_log_analytics_reader = false`.
- If `Key Vault Reader` assignment fails, ensure you can assign it at the effective management-group or targeted subscription scopes, or set `enable_key_vault_reader = false`.
- If `Reservations Reader`, `Reservations Contributor`, or `Savings plan Reader` assignments fail, ensure you can create RBAC assignments at `/providers/Microsoft.Capacity` and `/providers/Microsoft.BillingBenefits`, or disable them with `enable_reservations_reader = false`, `enable_reservations_contributor = false`, and `enable_savings_plan_reader = false`.
- If Microsoft Graph permission grants fail, ensure admin consent is allowed for the required Spotto Microsoft Graph application permissions in your tenant. The module intentionally does not request `Directory.Read.All`.
- If Cost Management exports fail with unsupported dataset or partitioning errors, remove `AmortizedCost` from `billing_export_dataset_types`, set `billing_export_actual_cost_definition_type = "Usage"` for agreements/scopes that do not support `ActualCost`, or set `billing_export_partition_data = false`.
- If billing export storage access fails, confirm the storage account allows public network access with authenticated access, anonymous blob access is disabled, the container is private, and the Spotto service principal has `Storage Blob Data Reader` on the export container.

## License

See `LICENSE`.
