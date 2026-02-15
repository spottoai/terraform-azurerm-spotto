Status: living
Last updated: 2026-02-15
Owner: Platform

# Usage & Deployment

## Requirements
- Terraform >= 1.3
- `hashicorp/azurerm` provider
- `hashicorp/azuread` provider
- `hashicorp/random` provider
- `hashicorp/time` provider

## Module usage
See `README.md` and `examples/` for module configuration and onboarding workflows.

## State management
Use a remote backend with encryption and access controls, because outputs include sensitive client secrets.

## Release workflow
Follow the standard process in `../core/DEPLOYMENT.md` unless a repo-specific exception is documented above.
