## Metadata

Status: complete
Approved: Yes — user instruction “fix terraform then too” on 2026-08-28
Iterations: 1
Last updated: 2026-08-28
Repo: terraform-azurerm-spotto
Domain: azure
Parent spec: N/A (single-repo parity change)
Spec location: specs/azure/policy-read-all-terraform-azurerm-spotto.md

## Summary

Bring Terraform onboarding into parity with the PowerShell onboarding path by granting the explicitly requested Microsoft Graph application permission `Policy.Read.All` for tenant-policy visibility.

## Scope (Repo-Specific)

In scope:
- Add `Policy.Read.All` to the existing Microsoft Graph application-role allowlist.
- Keep application-role IDs dynamically resolved from the Microsoft Graph service principal.
- Update root/module documentation and the changelog.
- Verify formatting, Terraform configuration validity, and permission parity.

Out of scope:
- Graph policy write permissions.
- Changes to Azure RBAC, Cost Management exports, module inputs, or outputs.
- Applying Terraform against a customer tenant.

## Open Questions

- None. The user explicitly requested Terraform parity.

## Assumptions and Constraints (Post-Recon)

- [x] `Policy.Read.All` is an application permission requiring admin consent (validated against Microsoft Learn).
- [x] The module already resolves every configured Graph role by value and assigns all roles other than the separately named `Application.Read.All` resource through `graph_additional_permissions`.
- Existing module inputs/outputs must remain backward compatible.

## Alternatives & Tradeoffs

- Hardcode the Microsoft Graph app-role GUID: rejected because the module already has safer role-value discovery.
- Add a new feature flag only for `Policy.Read.All`: rejected because the PowerShell onboarding path treats it as part of the approved governance permission set and the existing `enable_graph_permission` flag controls that set.

## Decision

Add `Policy.Read.All` to `local.graph_app_role_values`; the existing required-resource-access and app-role-assignment loops will wire it consistently with the other Graph governance permissions.

## Deferred Ideas

- Per-permission Graph feature flags.
- A broader Terraform test harness for all Azure onboarding resources.

## Success Criteria (Repo)

- Terraform and PowerShell onboarding declare the same eight Microsoft Graph application permissions.
- `Policy.Read.All` flows into both `required_resource_access` and `azuread_app_role_assignment.graph_additional_permissions` through the existing maps.
- No `Policy.ReadWrite*` permission is introduced.
- Both READMEs and the changelog describe tenant-policy visibility.

## Cross-Repo Touchpoints

- `spotto-tools` is the parity source for the eight-permission Graph governance allowlist; no files in that repo change here.

## Local Recon

- Entry points checked: `modules/onboarding/main.tf`, `modules/onboarding/variables.tf`.
- Existing patterns found: role-value allowlist -> dynamic role-ID lookup -> application manifest -> app-role assignments.
- Relevant docs: root `README.md`, module `README.md`, `CHANGELOG.md`, `DEPLOYMENT.md`.
- Existing automated test harness: none.

## Approach

- Extend the existing allowlist by one read-only role value.
- Update every user-facing description/list without changing the public Terraform variable shape.
- Use Terraform formatting/validation and an exact cross-repo allowlist comparison as verification.

## Tasks (Sequential)

1. Add Graph permission parity
   Files: `modules/onboarding/main.tf`
   Action: Add `Policy.Read.All` to `local.graph_app_role_values`; retain dynamic lookup and existing assignment loops.
   Verify: Exact allowlist comparison reports no difference from `spotto-tools`; scan excludes `Policy.ReadWrite*`.
   Done: The map contains eight unique application permissions and includes `Policy.Read.All`.
2. Update permission documentation
   Files: `README.md`, `modules/onboarding/README.md`, `modules/onboarding/variables.tf`, `CHANGELOG.md`
   Action: Add tenant-policy visibility and list `Policy.Read.All` alongside existing Graph permissions.
   Verify: Repository search finds the permission in implementation and both permission lists; input descriptions mention tenant policy.
   Done: Runtime and documentation contracts agree.
3. Verify the module
   Files: all changed files and this spec
   Action: Run `terraform fmt -check -recursive`, `terraform validate` where provider initialization permits, `git diff --check`, permission/security scans, and inspect the final diff.
   Verify: Commands exit successfully or any environment-only validation gap is recorded.
   Done: No formatting, syntax, write-permission, secret, dependency, or backward-compatibility issue remains.

## Test Strategy

- Unit: N/A — repository has no Terraform test harness and this change extends an existing declarative allowlist without new branching logic.
- Integration: `terraform validate` after provider initialization, without planning or applying customer resources.
- Contract: exact comparison against the PowerShell permission allowlist.
- E2E: deferred to a controlled tenant `terraform plan/apply`; no customer credentials are available here.

## Definition of Done (DoD)

### Feature Criteria

- The Terraform plan model requests and assigns `Policy.Read.All` whenever `enable_graph_permission = true`.
- Existing opt-out behavior remains unchanged when `enable_graph_permission = false`.

### Completion Checklist

- [x] Unit tests N/A — no existing Terraform test harness and no new branching logic
- [x] Feature validated with formatting, configuration, and parity checks
- [x] Code quality/security review completed
- [x] Local module documentation and changelog updated
- [x] Docs repo update N/A — no docs repo is in scope
- [x] MCP update N/A — no MCP contract changes
- [x] Swagger/OpenAPI update N/A — no API changes
- [x] Demo data update N/A — no demo behavior

## Risks and Mitigations

- Risk: persistent tenant-wide read access is broader than the current module.
  Mitigation: the user explicitly approved the permission; add only `Policy.Read.All`, document admin consent, and scan for policy write roles.
- Risk: role GUID drift or incorrect hardcoding.
  Mitigation: reuse runtime lookup by role value and `allowed_member_types = Application`.
- Risk: Terraform applies an unexpected replacement.
  Mitigation: only extend the application permission set and app-role assignment map; do not change resource names, inputs, or outputs.

## Rollback / Feature Flag

- Existing `enable_graph_permission` remains the feature-level opt-out. Rollback this allowlist/doc addition to remove the newly managed role assignment.

## Security Considerations

- Data access: adds read-only access to organizational policy data exposed by Microsoft Graph.
- Auth/authz: application permission requires tenant administrator consent; no write permission is added.
- Secrets/dependencies: unchanged.

## Runtime Environment

- Format: `terraform fmt -check -recursive`
- Validate: `terraform -chdir=modules/onboarding init -backend=false` then `terraform -chdir=modules/onboarding validate`
- Apply: intentionally not run in this environment.

## References

- https://learn.microsoft.com/en-us/graph/permissions-reference
- https://learn.microsoft.com/en-us/graph/api/adminconsentrequestpolicy-get?view=graph-rest-1.0
- `C:/VersionControlGitHub/spotto/spotto-tools/onboarding/azure/Setup-SpottoAzure.ps1`

## Verification Evidence

- `terraform fmt -check -recursive` passed.
- Isolated `terraform init -backend=false` and `terraform validate` passed with the module copied to a system temporary directory.
- Exact cross-repo comparison found eight matching, unique Graph application permissions.
- `git diff --check` passed; policy write-permission and secret scans found no additions.
- Live `terraform plan/apply` remains intentionally deferred because it requires customer tenant credentials and would propose or create tenant resources.
