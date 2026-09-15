# Changelog

## Unreleased

- Added explicit opt-in `Microsoft.Security` resource provider registration on every targeted subscription so authorized operators can enable Defender for Cloud secure score APIs without breaking restricted Terraform applies.
- Fixed provider-backed plans by canonicalizing full built-in role definition IDs and making initial backfill instance keys plan-known.
- Prevented deterministic naming from replacing existing module-created billing storage, added migration-safe management-group RBAC moves, and documented the one-time backfill state-key migration.
- Removed implicit tenant-root Azure Reader from targeted subscription onboarding while retaining Management Group Reader hierarchy/authorization metadata and subscription Key Vault coverage.
- Existing storage network widening and existing-source Blob Data Reader are now separate explicit authorization choices; handoff inputs and provider tenants are validated against the portal/API contract.
- Preserved the calendar-keyed backfill output contract, added a stable-key companion output, and decoupled portal handoff limits from Azure export provisioning for large estates.
- Protected policy/customer storage tags from removal after creation and added explicit large-backfill/provider-registration operational guidance.
- Split the onboarding implementation into focused identity, billing export, and RBAC files and raised the minimum Terraform version to 1.5.
- Aligned the onboarding module with the PowerShell Recommended profile: Key Vault Reader is enabled, management-group Monitoring Reader can cover explicit visible groups, and Reservations Contributor is now opt-in.
- Added PowerShell-compatible application ownership tags and deterministic, tenant-tagged billing export storage naming for new storage while retaining existing state-recorded names.
- Added explicit management-group EA Usage exports and declarative reuse of unmanaged billing-, management-group-, and subscription-scope recurring exports with opt-in container-level Blob Data Reader.
- Added the sensitive versioned `azure_manual_onboarding_json` portal handoff output, including managed and explicitly reused billing source locators.
- Disabled imperative recurring export runs by default because AzAPI resource actions repeat on subsequent applies; backfill runs remain opt-in.
- Added Terraform-native mock-provider parity tests for permissions, billing exports, storage ownership, and the portal handoff contract.
- Added an enabled-by-default `Security Reader` assignment on each targeted subscription for Defender for Cloud assessments, secure score, and security posture.
- Added Microsoft Graph `LicenseAssignment.Read.All` application permission for subscribed-license coverage used by tenant MFA posture analysis, aligning Terraform onboarding with the PowerShell and cloud-engine permission contract.
- Added Microsoft Graph `Policy.Read.All` application permission for tenant-policy visibility, aligning Terraform onboarding with the PowerShell onboarding path.
- Added a separate, disabled-by-default Azure Policy exemption permission option with exact subscription actions and explicit action-only management-group scopes for inherited assignments.
- Initial onboarding module.
- Added `Monitoring Reader` and `Log Analytics Data Reader` subscription assignments to the onboarding module.
- Align `assign_reader_to_all_subscriptions` with onboarding guidance by assigning `Reader` at tenant root scope (`/`) instead of creating one subscription-level assignment per current subscription.
- Clarified onboarding docs for governance-related tenant permissions, optional monitoring/log analytics access, and Microsoft Graph `Application.Read.All` usage for applications and service principals without widening to `Directory.Read.All`.
- Switched optional workspace log access from `Log Analytics Data Reader` to `Log Analytics Reader`, assigning it at the root management group for tenant-wide onboarding and preserving a deprecated Terraform alias for backward compatibility.
- Added opt-in Cost Management billing export setup, including explicit subscription-scoped export storage, private container creation, `Storage Blob Data Reader`, daily actual/amortized exports, and previous-month backfill export definitions with opt-in run queueing.
- Aligned Terraform onboarding with the PowerShell onboarding script by registering `Microsoft.CostManagementExports` on the billing export storage host subscription, deriving that host subscription from existing storage account IDs, and using root-qualified built-in role definition IDs for AzAPI tenant/provider-scope role assignments.
- Changed the default Azure AD application display name from `Spotto AI` to `Spotto` and added default `Reservations Contributor` assignment at `/providers/Microsoft.Capacity` for reservation refund quote and management workflows.
- Expanded Microsoft Graph application permissions for Entra Global Admin/PIM visibility, group membership, user profile, and audit log coverage while continuing to avoid `Directory.Read.All`.
