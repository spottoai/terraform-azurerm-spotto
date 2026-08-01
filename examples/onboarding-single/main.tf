variable "subscription_id" {
  description = "Subscription ID to grant Reader access."
  type        = string
}

module "spotto_onboarding" {
  source = "../../modules/onboarding"

  subscription_ids = [var.subscription_id]

  # Optional, highly recommended: create Cost Management exports to customer-owned
  # Azure Storage so Spotto can read billing data from exports instead of making
  # repeated Cost Management API calls.
  # enable_billing_exports = true

  # Separate opt-in for narrowly scoped Azure Policy exemption creation.
  # grant_policy_exemption_permissions = true

  # Add only management groups that own inherited initiative assignments.
  # policy_assignment_exempt_scopes = [
  #   "/providers/Microsoft.Management/managementGroups/production"
  # ]
}

output "application_client_id" {
  value = module.spotto_onboarding.application_client_id
}

output "tenant_id" {
  value = module.spotto_onboarding.tenant_id
}

output "client_secret" {
  value     = module.spotto_onboarding.client_secret
  sensitive = true
}
