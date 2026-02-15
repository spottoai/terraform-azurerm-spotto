---
name: terraform-azurerm-spotto-architecture
description: Repo-specific architecture for Spotto Azure onboarding Terraform modules.
---

Status: living
Last updated: 2026-02-15
Owner: TBD
Related docs: README.md, CHANGELOG.md, DEPLOYMENT.md, ../core/skills/system-architecture/references/system-map.md

# terraform-azurerm-spotto-architecture

## Purpose
Defines the architecture of the Terraform modules used to onboard Azure environments into Spotto.

## Scope
- Covers module structure, inputs/outputs, and onboarding workflow.
- Excludes runtime services and UI/API behavior.

## System context
- Upstream: Customers or operators applying Terraform.
- Downstream: Azure AD app registrations, service principals, role assignments, and permissions.
- Primary responsibility: create onboarding identities and permissions required by Spotto.

## Key components
- `modules/onboarding/` - main onboarding module.
- `examples/` - usage examples for single/multi-subscription setups.

## Data flow (happy path)
1. Operator applies Terraform module with subscription IDs.
2. Module creates app/service principal and assigns roles.
3. Outputs provide credentials for Spotto onboarding.

## Runtime & deployment notes
- Requires Terraform and Azure providers; see `README.md`.
- State includes secrets and must be protected.

## Integration boundaries & invariants
- Permission scopes must match Spotto onboarding requirements.
- Changes to outputs should remain backward compatible for existing automation.
