output "application_client_id" {
  description = "Application (client) ID for the Spotto service principal."
  value       = azuread_application.spotto.client_id
}

output "application_object_id" {
  description = "Object ID of the Azure AD application."
  value       = azuread_application.spotto.object_id
}

output "service_principal_object_id" {
  description = "Object ID of the Azure AD service principal."
  value       = azuread_service_principal.spotto.object_id
}

output "tenant_id" {
  description = "Tenant ID used for the deployment."
  value       = local.tenant_id
}

output "client_secret" {
  description = "Client secret for the application (sensitive)."
  value       = try(azuread_application_password.spotto[0].value, null)
  sensitive   = true
}

output "client_secret_expiry" {
  description = "Expiration timestamp for the client secret."
  value       = try(azuread_application_password.spotto[0].end_date, var.client_secret_end_date)
}

output "subscription_ids" {
  description = "Subscription IDs resolved for the deployment. In tenant-wide Reader mode, this is the current subscription snapshot, not a limit on inherited root-scope access."
  value       = local.effective_subscription_ids
}

output "management_group_ids" {
  description = "Management group IDs used for governance role assignments."
  value       = sort(tolist(local.effective_management_group_ids))
}

output "write_permissions_enabled" {
  description = "Whether the optional write permissions were enabled."
  value       = var.grant_optional_write_permissions
}

output "custom_role_definition_id" {
  description = "Role definition resource ID for the optional custom role."
  value       = try(azurerm_role_definition.spotto_write[0].role_definition_resource_id, null)
}

output "policy_exemption_permissions_enabled" {
  description = "Whether subscription-scoped Azure Policy exemption permissions were enabled."
  value       = var.grant_policy_exemption_permissions
}

output "policy_assignment_exempt_scopes" {
  description = "Explicit management-group policy assignment scopes granted the exempt action."
  value       = sort(tolist(local.policy_assignment_exempt_scopes))
}

output "policy_assignment_exempt_role_definition_ids" {
  description = "Role definition resource IDs keyed by explicit management-group policy assignment scope."
  value = {
    for scope, role in azurerm_role_definition.policy_assignment_exempt : scope => role.role_definition_resource_id
  }
}

output "billing_exports_enabled" {
  description = "Whether Cost Management billing exports were enabled."
  value       = var.enable_billing_exports
}

output "billing_export_storage_account_id" {
  description = "Storage account resource ID used for billing exports."
  value       = local.billing_export_storage_account_id
}

output "billing_export_storage_subscription_id" {
  description = "Subscription ID used for module-created billing export storage."
  value       = var.enable_billing_exports && var.create_billing_export_storage_account ? local.billing_export_storage_subscription_id : null
}

output "billing_export_container_id" {
  description = "Blob container resource ID used for billing exports."
  value       = try(azapi_resource.billing_export_container[0].id, null)
}

output "billing_export_recurring_export_ids" {
  description = "Cost Management recurring export resource IDs keyed by subscription ID and dataset type."
  value       = { for key, export in azapi_resource.billing_export_recurring : key => export.id }
}

output "billing_export_backfill_export_ids" {
  description = "Cost Management backfill export resource IDs keyed by subscription ID, dataset type, and calendar period (YYYYMM), preserving the pre-1.1 output contract."
  value = {
    for stable_key, export in local.billing_export_backfill_exports :
    "${export.subscription_id}|${export.dataset_type}|${export.period_name}" => azapi_resource.billing_export_backfill[stable_key].id
  }
}

output "billing_export_backfill_export_stable_ids" {
  description = "Cost Management backfill export resource IDs keyed by subscription ID, dataset type, and stable months-ago period."
  value       = { for key, export in azapi_resource.billing_export_backfill : key => export.id }
}

output "billing_export_management_group_export_ids" {
  description = "Cost Management Usage recurring export resource IDs keyed by management group ID."
  value       = { for key, export in azapi_resource.billing_export_management_group_recurring : key => export.id }
}

output "azure_manual_onboarding_json" {
  description = "Versioned Spotto portal manual-onboarding JSON. Billing sources are omitted when they exceed the portal count or size limit; check azure_manual_onboarding_billing_exports_eligible. Sensitive because it contains the generated client secret when create_client_secret is true."
  value       = jsonencode(local.azure_manual_onboarding_payload)
  sensitive   = true
}

output "azure_manual_onboarding_billing_exports_eligible" {
  description = "Whether all configured billing export sources fit the portal handoff limit of 50 sources and 24 KiB. Azure resources remain independently manageable when false."
  value       = local.azure_manual_onboarding_billing_exports_eligible
}
