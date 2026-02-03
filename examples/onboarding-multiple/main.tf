variable "subscription_ids" {
  description = "Subscription IDs to grant Reader access."
  type        = list(string)
}

module "spotto_onboarding" {
  source = "../../modules/onboarding"

  subscription_ids = var.subscription_ids
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
