variable "assign_reader_to_all_subscriptions" {
  description = "Whether to grant Reader once at tenant root scope (/) so it inherits to all current and future subscriptions."
  type        = bool
  default     = false
}

variable "subscription_ids" {
  description = "List of subscription IDs to grant Reader access. Ignored when assign_reader_to_all_subscriptions is true."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for id in var.subscription_ids : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", id))
    ])
    error_message = "subscription_ids must contain valid subscription UUIDs."
  }

  validation {
    condition     = length(distinct([for id in var.subscription_ids : lower(id)])) == length(var.subscription_ids)
    error_message = "subscription_ids must not contain case-insensitive duplicates."
  }
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
  description = "Optional tenant ID assertion. The effective tenant must equal the AzureRM, AzureAD, and AzAPI provider tenants."
  type        = string
  default     = null

  validation {
    condition     = var.tenant_id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.tenant_id))
    error_message = "tenant_id must be a valid UUID when provided."
  }
}

variable "root_management_group_id" {
  description = "Optional management group ID to use for tenant-level role assignments. Defaults to tenant ID."
  type        = string
  default     = null

  validation {
    condition = var.root_management_group_id == null || (
      var.root_management_group_id == trimspace(var.root_management_group_id) &&
      length(var.root_management_group_id) > 0 &&
      !contains([".", ".."], var.root_management_group_id) &&
      can(regex("^[^/%\\\\?#\\x00-\\x1F\\x7F]+$", var.root_management_group_id))
    )
    error_message = "root_management_group_id must be a normalized management group name/ID without path separators, reserved URL characters, or control characters."
  }
}

variable "management_group_ids" {
  description = "Explicit management group IDs to receive governance roles when the tenant-root management group is unavailable or additional visible groups are required. Defaults to root_management_group_id or the tenant ID."
  type        = set(string)
  default     = []

  validation {
    condition = alltrue([for id in var.management_group_ids :
      id == trimspace(id) &&
      length(id) > 0 &&
      !contains([".", ".."], id) &&
      can(regex("^[^/%\\\\?#\\x00-\\x1F\\x7F]+$", id))
    ])
    error_message = "management_group_ids must contain normalized management group names/IDs without path separators, reserved URL characters, or control characters."
  }

  validation {
    condition     = length(distinct([for id in var.management_group_ids : lower(id)])) == length(var.management_group_ids)
    error_message = "management_group_ids must not contain case-insensitive duplicates."
  }
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
  description = "Whether to assign Management Group Reader for hierarchy and authorization metadata, plus Azure Reader in tenant-wide or explicitly selected management-group mode."
  type        = bool
  default     = true
}

variable "enable_management_group_monitoring_reader" {
  description = "Whether to assign Monitoring Reader on tenant-wide or explicitly selected management-group scopes."
  type        = bool
  default     = true
}

variable "enable_key_vault_reader" {
  description = "Whether to assign Key Vault Reader for vault metadata. Tenant-wide or explicit management-group setup uses management-group scopes; otherwise targeted subscriptions are used."
  type        = bool
  default     = true
}

variable "grant_policy_exemption_permissions" {
  description = "Whether to add the least-privilege Azure Policy exemption actions to the subscription-scoped Spotto custom role. This is independent of grant_optional_write_permissions."
  type        = bool
  default     = false
}

variable "policy_assignment_exempt_scopes" {
  description = "Explicit management-group resource IDs whose inherited policy assignments Spotto may exempt. Empty by default; requires grant_policy_exemption_permissions."
  type        = set(string)
  default     = []

  validation {
    condition = alltrue([
      for scope in var.policy_assignment_exempt_scopes :
      can(regex("^/providers/Microsoft\\.Management/managementGroups/[^/]+$", scope))
    ])
    error_message = "policy_assignment_exempt_scopes may contain only management-group resource IDs."
  }

  validation {
    condition = length(distinct([
      for scope in var.policy_assignment_exempt_scopes : lower(trimspace(scope))
    ])) == length(var.policy_assignment_exempt_scopes)
    error_message = "policy_assignment_exempt_scopes must not contain case-insensitive duplicates."
  }
}

variable "policy_assignment_exempt_role_name" {
  description = "Name for the action-only custom role assigned at explicit management-group policy assignment scopes."
  type        = string
  default     = "Spotto Policy Assignment Exempt"
}

variable "enable_reservations_reader" {
  description = "Whether to assign Reservations Reader at /providers/Microsoft.Capacity."
  type        = bool
  default     = true
}

variable "enable_reservations_contributor" {
  description = "Whether to assign Reservations Contributor at /providers/Microsoft.Capacity for reservation refund quotes and management workflows."
  type        = bool
  default     = false
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

variable "enable_security_reader" {
  description = "Whether to assign Security Reader on each targeted subscription for Defender for Cloud assessments and security posture."
  type        = bool
  default     = true
}

variable "enable_security_resource_provider_registration" {
  description = "Whether to request Microsoft.Security registration on each targeted subscription. This requires Microsoft.Resources/subscriptions/providers/register/action and fails the apply when Azure rejects the request."
  type        = bool
  default     = false
}

variable "enable_log_analytics_reader" {
  description = "Whether to assign Log Analytics Reader. Tenant-wide mode uses effective management-group scopes; targeted mode uses subscriptions and also any explicit management_group_ids."
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
  description = "Whether to grant tenant-wide Microsoft Graph read-only application permissions for application inventory, tenant policy, license capacity/assignments, Entra admin role, PIM, group membership, user account metadata, audit/sign-in activity, and Microsoft 365/Copilot usage reports."
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
    condition     = var.billing_export_storage_account_id == null || can(regex("^/subscriptions/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/resourceGroups/[^/]+/providers/Microsoft\\.Storage/storageAccounts/[a-z0-9]{3,24}$", var.billing_export_storage_account_id))
    error_message = "billing_export_storage_account_id must be a storage account resource ID."
  }
}

variable "manage_billing_export_storage_account_settings" {
  description = "Whether to enforce export-compatible settings. Module-created storage is managed by default; existing storage also requires allow_existing_billing_export_storage_network_changes."
  type        = bool
  default     = true
}

variable "allow_existing_billing_export_storage_network_changes" {
  description = "Whether Terraform may enable public network access, set the default network action to Allow, and clear network rules on an existing billing export storage account."
  type        = bool
  default     = false
}

variable "billing_export_storage_subscription_id" {
  description = "Subscription ID for the billing export storage host. Defaults to the first targeted subscription when creating storage, or the subscription parsed from billing_export_storage_account_id when using existing storage."
  type        = string
  default     = null

  validation {
    condition     = var.billing_export_storage_subscription_id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.billing_export_storage_subscription_id))
    error_message = "billing_export_storage_subscription_id must be a valid subscription UUID when provided."
  }
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
  description = "Optional creation-time name for module-created billing export storage. New storage defaults to billingexports plus the tenant suffix; existing state retains its recorded name."
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
    condition = (
      var.billing_export_root_path == trimspace(var.billing_export_root_path) &&
      var.billing_export_root_path == trim(var.billing_export_root_path, "/") &&
      length(var.billing_export_root_path) > 0 &&
      length(var.billing_export_root_path) <= 512 &&
      can(regex("^[^%\\\\?#\\x00-\\x1F\\x7F]+$", var.billing_export_root_path)) &&
      alltrue([for segment in split("/", var.billing_export_root_path) : length(segment) > 0 && !contains([".", ".."], segment)])
    )
    error_message = "billing_export_root_path must be a normalized, non-empty portal-safe path without empty or dot segments."
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

variable "billing_export_management_group_ids" {
  description = "Explicit management group IDs where an EA Usage daily export should be created in addition to subscription Actual/Amortized exports."
  type        = set(string)
  default     = []

  validation {
    condition = alltrue([for id in var.billing_export_management_group_ids :
      id == trimspace(id) &&
      length(id) > 0 &&
      !contains([".", ".."], id) &&
      can(regex("^[^/%\\\\?#\\x00-\\x1F\\x7F]+$", id))
    ])
    error_message = "billing_export_management_group_ids must contain normalized management group names/IDs without path separators, reserved URL characters, or control characters."
  }

  validation {
    condition     = length(distinct([for id in var.billing_export_management_group_ids : lower(id)])) == length(var.billing_export_management_group_ids)
    error_message = "billing_export_management_group_ids must not contain case-insensitive duplicates."
  }
}

variable "grant_existing_billing_export_storage_reader" {
  description = "Whether to grant Spotto Storage Blob Data Reader on destinations declared in existing_billing_export_sources. This is an explicit authorization boundary because Terraform does not verify those export destinations."
  type        = bool
  default     = false
}

variable "existing_billing_export_sources" {
  description = "Explicit existing recurring exports to include in the Spotto handoff. Terraform does not manage the definitions or storage; Blob Data Reader is separately opt-in."
  type = list(object({
    dataset_type       = string
    scope_type         = string
    scope_path         = string
    export_name        = string
    storage_account_id = string
    container_name     = string
    root_folder_path   = string
  }))
  default = []

  validation {
    condition     = length(var.existing_billing_export_sources) <= 50
    error_message = "existing_billing_export_sources may contain at most 50 sources."
  }

  validation {
    condition = alltrue([
      for source in var.existing_billing_export_sources :
      contains(["actual", "amortized"], source.dataset_type) &&
      contains(["subscription", "resourceGroup", "managementGroup", "billingAccount", "billingProfile", "invoiceSection", "department", "enrollmentAccount", "partnerCustomer"], source.scope_type)
    ])
    error_message = "Each existing billing source must use dataset_type actual/amortized and a supported onboarding scope_type."
  }

  validation {
    condition = alltrue([
      for source in var.existing_billing_export_sources :
      length(trimsuffix(trimspace(source.scope_path), "/")) <= 2048 &&
      can(regex("^[^%\\\\?#\\x00-\\x1F\\x7F]+$", trimsuffix(trimspace(source.scope_path), "/"))) &&
      alltrue([for segment in split("/", trimsuffix(trimspace(source.scope_path), "/")) : !contains([".", ".."], segment)]) &&
      length(trimspace(source.export_name)) > 0 &&
      length(trimspace(source.export_name)) <= 260 &&
      !contains([".", ".."], trimspace(source.export_name)) &&
      can(regex("^[^/\\\\?#\\x00-\\x1F\\x7F]+$", trimspace(source.export_name))) &&
      can(regex("^/subscriptions/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/resourceGroups/[^/]+/providers/Microsoft\\.Storage/storageAccounts/[a-z0-9]{3,24}$", source.storage_account_id)) &&
      can(regex("^[a-z0-9](?:[a-z0-9-]{1,61}[a-z0-9])$", source.container_name)) &&
      !can(regex("--", source.container_name)) &&
      length(trim(trimspace(source.root_folder_path), "/")) > 0 &&
      length(trim(trimspace(source.root_folder_path), "/")) <= 1024 &&
      can(regex("^[^%\\\\?#\\x00-\\x1F\\x7F]+$", trim(trimspace(source.root_folder_path), "/"))) &&
      alltrue([for segment in split("/", trim(trimspace(source.root_folder_path), "/")) : length(segment) > 0 && !contains([".", ".."], segment)])
    ])
    error_message = "Existing billing sources require portal-safe scope, export, storage, container, and non-empty root-folder values."
  }

  validation {
    condition = alltrue([
      for source in var.existing_billing_export_sources : can(regex(lookup({
        subscription      = "^/subscriptions/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
        resourceGroup     = "^/subscriptions/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/resourceGroups/[^/]+$"
        managementGroup   = "^/providers/Microsoft\\.Management/managementGroups/[^/]+$"
        billingAccount    = "^/providers/Microsoft\\.Billing/billingAccounts/[^/]+$"
        billingProfile    = "^/providers/Microsoft\\.Billing/billingAccounts/[^/]+/billingProfiles/[^/]+$"
        invoiceSection    = "^/providers/Microsoft\\.Billing/billingAccounts/[^/]+/billingProfiles/[^/]+/invoiceSections/[^/]+$"
        department        = "^/providers/Microsoft\\.Billing/billingAccounts/[^/]+/departments/[^/]+$"
        enrollmentAccount = "^/providers/Microsoft\\.Billing/billingAccounts/[^/]+/enrollmentAccounts/[^/]+$"
        partnerCustomer   = "^/providers/Microsoft\\.Billing/billingAccounts/[^/]+/customers/[^/]+$"
      }, source.scope_type, "^$"), trimsuffix(trimspace(source.scope_path), "/")))
    ])
    error_message = "Each existing billing source scope_path must match its declared scope_type."
  }

  validation {
    condition = length(distinct([
      for source in var.existing_billing_export_sources :
      lower("${trimsuffix(trimspace(source.scope_path), "/")}|${trimspace(source.export_name)}|${source.dataset_type}")
    ])) == length(var.existing_billing_export_sources)
    error_message = "existing_billing_export_sources must not contain duplicate scope/export/dataset locators."
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
  description = "Whether to queue recurring export runs during apply. Disabled by default because AzAPI resource actions repeat on subsequent applies. Enable for one apply only when an immediate run is required."
  type        = bool
  default     = false
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
    condition = (
      var.billing_export_backfill_month_count >= 0 &&
      var.billing_export_backfill_month_count <= 36 &&
      floor(var.billing_export_backfill_month_count) == var.billing_export_backfill_month_count
    )
    error_message = "billing_export_backfill_month_count must be a whole number between 0 and 36."
  }
}

variable "enable_billing_export_backfill_runs" {
  description = "Whether to queue backfill runs during apply. Defaults to false because AzAPI actions repeat on subsequent applies and Terraform cannot observe whether Azure completed a previous run. Enable for one apply only."
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
