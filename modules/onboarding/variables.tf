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
  default     = "Spotto"
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

variable "enable_reservations_contributor" {
  description = "Whether to assign Reservations Contributor at /providers/Microsoft.Capacity for reservation refund quotes and management workflows."
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

variable "enable_billing_exports" {
  description = "Whether to configure Cost Management billing exports to Azure Storage for the targeted subscriptions."
  type        = bool
  default     = false
}

variable "create_billing_export_storage_account" {
  description = "Whether to create a storage account for billing exports. When false, billing_export_storage_account_id must be provided if billing exports are enabled."
  type        = bool
  default     = true
}

variable "billing_export_storage_account_id" {
  description = "Existing storage account resource ID to use for billing exports when create_billing_export_storage_account is false."
  type        = string
  default     = null

  validation {
    condition     = var.billing_export_storage_account_id == null || can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.Storage/storageAccounts/[^/]+$", var.billing_export_storage_account_id))
    error_message = "billing_export_storage_account_id must be a storage account resource ID."
  }
}

variable "manage_billing_export_storage_account_settings" {
  description = "Whether to enforce billing export storage account settings such as TLS 1.2, HTTPS-only traffic, public network access, Azure services bypass, and disabled anonymous blob access."
  type        = bool
  default     = true
}

variable "billing_export_storage_subscription_id" {
  description = "Subscription ID for the billing export storage host. Defaults to the first targeted subscription when creating storage, or the subscription parsed from billing_export_storage_account_id when using existing storage."
  type        = string
  default     = null
}

variable "enable_billing_export_resource_provider_registration" {
  description = "Whether to request Microsoft.CostManagement registration on targeted subscriptions; Microsoft.CostManagement, Microsoft.CostManagementExports, and optionally Microsoft.Storage on the storage host subscription."
  type        = bool
  default     = true
}

variable "billing_export_resource_group_name" {
  description = "Resource group name for the module-created billing export storage account."
  type        = string
  default     = "rg-spotto-cost-exports"
}

variable "billing_export_location" {
  description = "Azure region for the module-created billing export resource group and storage account."
  type        = string
  default     = "australiaeast"
}

variable "billing_export_storage_account_name" {
  description = "Optional name for the module-created billing export storage account. Defaults to a generated spotto-prefixed name."
  type        = string
  default     = null

  validation {
    condition     = var.billing_export_storage_account_name == null || can(regex("^[a-z0-9]{3,24}$", var.billing_export_storage_account_name))
    error_message = "billing_export_storage_account_name must be 3-24 lowercase letters and numbers."
  }
}

variable "billing_export_container_name" {
  description = "Blob container name for Spotto billing exports."
  type        = string
  default     = "spotto-cost-exports"

  validation {
    condition     = length(var.billing_export_container_name) >= 3 && length(var.billing_export_container_name) <= 63 && can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.billing_export_container_name)) && !can(regex("--", var.billing_export_container_name))
    error_message = "billing_export_container_name must be a valid Azure blob container name: 3-63 lowercase letters, numbers, and single hyphens, starting and ending with a letter or number."
  }
}

variable "billing_export_root_path" {
  description = "Root folder path in the billing export container."
  type        = string
  default     = "spotto"

  validation {
    condition     = length(trim(var.billing_export_root_path, "/")) > 0 && var.billing_export_root_path == trim(var.billing_export_root_path, "/")
    error_message = "billing_export_root_path must be non-empty and must not start or end with '/'."
  }
}

variable "billing_export_dataset_types" {
  description = "Cost Management export datasets to create. Remove AmortizedCost if it is unsupported for the Azure agreement/scope."
  type        = list(string)
  default     = ["ActualCost", "AmortizedCost"]

  validation {
    condition     = alltrue([for dataset_type in var.billing_export_dataset_types : contains(["ActualCost", "AmortizedCost"], dataset_type)])
    error_message = "billing_export_dataset_types may only contain ActualCost and AmortizedCost."
  }
}

variable "billing_export_actual_cost_definition_type" {
  description = "Definition type to use for ActualCost exports. Set to Usage for agreements/scopes where Azure does not support ActualCost."
  type        = string
  default     = "ActualCost"

  validation {
    condition     = contains(["ActualCost", "Usage"], var.billing_export_actual_cost_definition_type)
    error_message = "billing_export_actual_cost_definition_type must be ActualCost or Usage."
  }
}

variable "billing_export_partition_data" {
  description = "Whether to request partitioned billing export data. Set to false for agreements/scopes where Azure does not support partitionData."
  type        = bool
  default     = true
}

variable "enable_billing_export_immediate_runs" {
  description = "Whether to queue an immediate run for newly managed recurring billing exports."
  type        = bool
  default     = true
}

variable "enable_billing_export_backfill" {
  description = "Whether to create inactive one-time billing export definitions for previous closed months."
  type        = bool
  default     = true
}

variable "billing_export_backfill_month_count" {
  description = "Number of previous closed months to configure as one-time backfill exports."
  type        = number
  default     = 13

  validation {
    condition     = var.billing_export_backfill_month_count >= 0 && var.billing_export_backfill_month_count <= 36
    error_message = "billing_export_backfill_month_count must be between 0 and 36."
  }
}

variable "enable_billing_export_backfill_runs" {
  description = "Whether to queue runs for the one-time backfill billing exports. Defaults to false because Terraform managed actions cannot detect whether Azure completed a previous one-time run."
  type        = bool
  default     = false
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
