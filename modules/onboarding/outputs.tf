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

output "write_permissions_enabled" {
  description = "Whether the optional write permissions were enabled."
  value       = var.grant_optional_write_permissions
}

output "custom_role_definition_id" {
  description = "Role definition resource ID for the optional custom role."
  value       = try(azurerm_role_definition.spotto_write[0].role_definition_resource_id, null)
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
  description = "Cost Management backfill export resource IDs keyed by subscription ID, dataset type, and period."
  value       = { for key, export in azapi_resource.billing_export_backfill : key => export.id }
}
