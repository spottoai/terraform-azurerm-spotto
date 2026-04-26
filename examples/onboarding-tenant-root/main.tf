module "spotto_onboarding" {
  source = "../../modules/onboarding"

  assign_reader_to_all_subscriptions = true

  # Keep this example runnable for operators who have tenant-root Reader assignment rights
  # but do not want to require subscription-scoped or provider-scoped RBAC. Management-group
  # assignments remain enabled by default; disable enable_management_group_reader and
  # enable_log_analytics_reader too if you cannot create root management group assignments.
  enable_monitoring_reader   = false
  enable_reservations_reader = false
  enable_savings_plan_reader = false
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
