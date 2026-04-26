variable "assign_reader_to_all_subscriptions" {
  description = "Whether to grant Reader once at tenant root scope (/) so it inherits to all current and future subscriptions."
  type        = bool
  default     = false
}

variable "subscription_ids" {
  description = "List of subscription IDs to grant Reader access. Ignored when assign_reader_to_all_subscriptions is true."
  type        = list(string)
  default     = []
}

variable "app_name" {
  description = "Display name for the Azure AD application."
  type        = string
  default     = "Spotto AI"
}

variable "custom_role_name" {
  description = "Name for the optional custom role used for write permissions."
  type        = string
  default     = "Spotto Access"
}

variable "grant_optional_write_permissions" {
  description = "Whether to create and assign the optional custom role."
  type        = bool
  default     = false
}

variable "tenant_id" {
  description = "Optional tenant ID override. Defaults to the current client tenant."
  type        = string
  default     = null
}

variable "root_management_group_id" {
  description = "Optional management group ID to use for tenant-level role assignments. Defaults to tenant ID."
  type        = string
  default     = null
}

variable "create_client_secret" {
  description = "Whether to create a new client secret for the application."
  type        = bool
  default     = true
}

variable "client_secret_end_date" {
  description = "Optional RFC3339 timestamp to set the client secret expiration. Defaults to 12 months from creation."
  type        = string
  default     = null
}

variable "enable_management_group_reader" {
  description = "Whether to assign Management Group Reader at the root management group for management group hierarchy and tenant governance metadata visibility."
  type        = bool
  default     = true
}

variable "enable_reservations_reader" {
  description = "Whether to assign Reservations Reader at /providers/Microsoft.Capacity."
  type        = bool
  default     = true
}

variable "enable_savings_plan_reader" {
  description = "Whether to assign Savings plan Reader at /providers/Microsoft.BillingBenefits."
  type        = bool
  default     = true
}

variable "enable_monitoring_reader" {
  description = "Whether to assign Monitoring Reader on each targeted subscription."
  type        = bool
  default     = true
}

variable "enable_log_analytics_reader" {
  description = "Whether to assign Log Analytics Reader. When assign_reader_to_all_subscriptions is true, the module assigns it once at the root management group for tenant-wide workspace log access; otherwise it assigns it on each targeted subscription."
  type        = bool
  default     = true
}

variable "enable_log_analytics_data_reader" {
  description = "Deprecated alias for enable_log_analytics_reader. When set, this value overrides enable_log_analytics_reader."
  type        = bool
  default     = null
  nullable    = true
}

variable "enable_graph_permission" {
  description = "Whether to grant Microsoft Graph Application.Read.All so Spotto can read applications and service principals for governance and credential posture."
  type        = bool
  default     = true
}

variable "service_principal_propagation_delay" {
  description = "Delay to allow the service principal to propagate before role assignments. Use \"0s\" to disable."
  type        = string
  default     = "30s"
}

variable "custom_role_propagation_delay" {
  description = "Delay to allow the custom role definition to propagate before assignments. Use \"0s\" to disable."
  type        = string
  default     = "10s"
}
