variable "subscription_id" {
  description = "Subscription ID to grant Reader access."
  type        = string
}

module "spotto_onboarding" {
  source = "../../modules/onboarding"

  subscription_ids = [var.subscription_id]
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
