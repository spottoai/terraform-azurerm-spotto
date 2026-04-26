# Changelog

## Unreleased

- Initial onboarding module.
- Added `Monitoring Reader` and `Log Analytics Data Reader` subscription assignments to the onboarding module.
- Align `assign_reader_to_all_subscriptions` with onboarding guidance by assigning `Reader` at tenant root scope (`/`) instead of creating one subscription-level assignment per current subscription.
- Clarified onboarding docs for governance-related tenant permissions, optional monitoring/log analytics access, and Microsoft Graph `Application.Read.All` usage for applications and service principals without widening to `Directory.Read.All`.
- Switched optional workspace log access from `Log Analytics Data Reader` to `Log Analytics Reader`, assigning it at the root management group for tenant-wide onboarding and preserving a deprecated Terraform alias for backward compatibility.
