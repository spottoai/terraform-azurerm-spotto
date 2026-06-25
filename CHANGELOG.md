# Changelog

## Unreleased

- Initial onboarding module.
- Added `Monitoring Reader` and `Log Analytics Data Reader` subscription assignments to the onboarding module.
- Align `assign_reader_to_all_subscriptions` with onboarding guidance by assigning `Reader` at tenant root scope (`/`) instead of creating one subscription-level assignment per current subscription.
- Clarified onboarding docs for governance-related tenant permissions, optional monitoring/log analytics access, and Microsoft Graph `Application.Read.All` usage for applications and service principals without widening to `Directory.Read.All`.
- Switched optional workspace log access from `Log Analytics Data Reader` to `Log Analytics Reader`, assigning it at the root management group for tenant-wide onboarding and preserving a deprecated Terraform alias for backward compatibility.
- Added opt-in Cost Management billing export setup, including explicit subscription-scoped export storage, private container creation, `Storage Blob Data Reader`, daily actual/amortized exports, and previous-month backfill export definitions with opt-in run queueing.
- Aligned Terraform onboarding with the PowerShell onboarding script by registering `Microsoft.CostManagementExports` on the billing export storage host subscription, deriving that host subscription from existing storage account IDs, and using root-qualified built-in role definition IDs for AzAPI tenant/provider-scope role assignments.
- Changed the default Azure AD application display name from `Spotto AI` to `Spotto` and added default `Reservations Contributor` assignment at `/providers/Microsoft.Capacity` for reservation refund quote and management workflows.
- Expanded Microsoft Graph application permissions for Entra Global Admin/PIM visibility, group membership, user profile, and audit log coverage while continuing to avoid `Directory.Read.All`.
