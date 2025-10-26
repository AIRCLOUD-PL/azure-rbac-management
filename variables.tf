# RBAC Management Module Variables

# ===================================================================
# ORGANIZATION AND NAMING
# ===================================================================

variable "organization_prefix" {
  description = "Organization prefix for group naming (e.g., 'aircloud', 'company')"
  type        = string
  validation {
    condition     = length(var.organization_prefix) <= 20 && can(regex("^[a-zA-Z0-9-]+$", var.organization_prefix))
    error_message = "Organization prefix must be 20 characters or less and contain only alphanumeric characters and hyphens"
  }
}

variable "environments" {
  description = "List of environments to create RBAC groups for"
  type        = list(string)
  default     = ["dev", "test", "prod"]
  validation {
    condition     = length(var.environments) > 0
    error_message = "At least one environment must be specified"
  }
}

variable "projects" {
  description = "List of projects to create project-specific RBAC groups for (optional)"
  type        = list(string)
  default     = []
}

variable "create_project_groups" {
  description = "Whether to create project-specific groups in addition to environment groups"
  type        = bool
  default     = false
}

# ===================================================================
# GROUP OWNERSHIP AND MANAGEMENT
# ===================================================================

variable "group_owners" {
  description = "List of object IDs that will be owners of created Azure AD groups"
  type        = list(string)
  validation {
    condition     = length(var.group_owners) > 0
    error_message = "At least one group owner must be specified"
  }
}

variable "default_group_owners" {
  description = "Default owners to add to all groups (in addition to group_owners)"
  type        = list(string)
  default     = []
}

# ===================================================================
# RESOURCE SCOPES
# ===================================================================

variable "resource_groups" {
  description = "Map of resource groups to assign permissions to. Key is RG name, value contains RG details."
  type = map(object({
    id                = string
    name              = string
    environment       = string
    resource_types    = optional(list(string), []) # Types of resources in this RG
    criticality_level = optional(string, "medium") # low, medium, high, critical
  }))
  default = null
}

variable "custom_scopes" {
  description = "Additional custom scopes for role assignments (e.g., specific resources)"
  type = map(object({
    scope       = string
    description = string
    environment = string
  }))
  default = {}
}

# ===================================================================
# ROLE ASSIGNMENT CONTROLS
# ===================================================================

variable "enable_subscription_assignments" {
  description = "Enable role assignments at subscription level"
  type        = bool
  default     = true
}

variable "enable_resource_group_assignments" {
  description = "Enable role assignments at resource group level"
  type        = bool
  default     = true
}

variable "enable_custom_scope_assignments" {
  description = "Enable role assignments at custom scopes"
  type        = bool
  default     = false
}

# ===================================================================
# ROLE CUSTOMIZATION
# ===================================================================

variable "custom_role_definitions" {
  description = "Custom role definitions for specific needs"
  type = map(object({
    role_name    = string
    description  = string
    permissions  = list(string)
    environments = list(string) # Which environments this role applies to
    user_types   = list(string) # Which user types can have this role
  }))
  default = {}
}

variable "role_overrides" {
  description = "Override default roles for specific environment/user type combinations"
  type = map(object({
    environment = string
    user_type   = string
    roles       = list(string)
  }))
  default = {}
}

# ===================================================================
# ENVIRONMENT-SPECIFIC CONFIGURATIONS
# ===================================================================

variable "environment_specific_roles" {
  description = "Additional roles for specific environments beyond defaults"
  type = map(object({
    non_technical = optional(list(string), [])
    technical     = optional(list(string), [])
    solo_project  = optional(list(string), [])
    admin         = optional(list(string), [])
  }))
  default = {}
}

variable "break_glass_accounts" {
  description = "Break glass accounts that get emergency access in production"
  type = map(object({
    object_id    = string
    display_name = string
    roles        = list(string)
    environments = list(string) # Which environments this applies to
  }))
  default = {}
}

# ===================================================================
# SECURITY AND COMPLIANCE
# ===================================================================

variable "require_mfa_for_privileged_roles" {
  description = "Require MFA for privileged roles (Owner, Contributor, etc.)"
  type        = bool
  default     = true
}

variable "privileged_roles" {
  description = "List of roles considered privileged (requiring additional security)"
  type        = list(string)
  default = [
    "Owner",
    "Contributor",
    "User Access Administrator",
    "Security Administrator",
    "Key Vault Administrator"
  ]
}

variable "audit_log_retention_days" {
  description = "Number of days to retain RBAC change audit logs"
  type        = number
  default     = 365
  validation {
    condition     = var.audit_log_retention_days >= 90 && var.audit_log_retention_days <= 2555
    error_message = "Audit log retention must be between 90 and 2555 days"
  }
}

# ===================================================================
# USER TYPE SPECIFIC SETTINGS
# ===================================================================

variable "non_technical_user_settings" {
  description = "Specific settings for non-technical users"
  type = object({
    max_role_assignments      = optional(number, 5)
    allowed_resource_types    = optional(list(string), ["Microsoft.KeyVault/vaults", "Microsoft.Storage/storageAccounts"])
    require_approval_for_prod = optional(bool, true)
    default_access_duration   = optional(string, "8h") # For Just-In-Time access
  })
  default = {}
}

variable "technical_user_settings" {
  description = "Specific settings for technical users"
  type = object({
    max_role_assignments      = optional(number, 15)
    allowed_resource_types    = optional(list(string), ["*"]) # All resource types
    require_approval_for_prod = optional(bool, true)
    default_access_duration   = optional(string, "24h")
    can_create_resources      = optional(bool, true)
  })
  default = {}
}

variable "solo_project_user_settings" {
  description = "Specific settings for solo project users"
  type = object({
    max_role_assignments      = optional(number, 10)
    allowed_resource_types    = optional(list(string), ["*"])
    require_approval_for_prod = optional(bool, false) # More autonomy for solo projects
    default_access_duration   = optional(string, "24h")
    can_create_resources      = optional(bool, true)
    resource_spending_limit   = optional(number, 1000) # USD per month
  })
  default = {}
}

variable "admin_user_settings" {
  description = "Specific settings for admin users"
  type = object({
    max_role_assignments      = optional(number, 50)
    allowed_resource_types    = optional(list(string), ["*"])
    require_approval_for_prod = optional(bool, false)
    default_access_duration   = optional(string, "permanent")
    can_manage_rbac           = optional(bool, true)
    emergency_access_enabled  = optional(bool, true)
  })
  default = {}
}

# ===================================================================
# INTEGRATION SETTINGS
# ===================================================================

variable "integrate_with_pim" {
  description = "Integrate with Azure AD Privileged Identity Management"
  type        = bool
  default     = false
}

variable "integrate_with_conditional_access" {
  description = "Create conditional access policies for RBAC groups"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for RBAC audit logging"
  type        = string
  default     = null
}

variable "notification_email" {
  description = "Email address for RBAC change notifications"
  type        = string
  default     = null
}

# ===================================================================
# RESOURCE-SPECIFIC ROLE MAPPINGS
# ===================================================================

variable "resource_type_role_mappings" {
  description = "Custom role mappings for specific resource types"
  type = map(object({
    non_technical = list(string)
    technical     = list(string)
    solo_project  = list(string)
    admin         = list(string)
  }))
  default = {
    # Key Vault specific roles
    "Microsoft.KeyVault/vaults" = {
      non_technical = ["Key Vault Secrets User"]
      technical     = ["Key Vault Administrator", "Key Vault Secrets Officer"]
      solo_project  = ["Key Vault Administrator"]
      admin         = ["Key Vault Administrator"]
    }

    # Storage specific roles
    "Microsoft.Storage/storageAccounts" = {
      non_technical = ["Storage Blob Data Reader"]
      technical     = ["Storage Blob Data Contributor", "Storage Account Contributor"]
      solo_project  = ["Storage Blob Data Owner"]
      admin         = ["Storage Account Contributor"]
    }

    # Compute specific roles
    "Microsoft.Compute/virtualMachines" = {
      non_technical = ["Virtual Machine User Login"]
      technical     = ["Virtual Machine Contributor"]
      solo_project  = ["Virtual Machine Contributor"]
      admin         = ["Virtual Machine Contributor"]
    }

    # Network specific roles
    "Microsoft.Network/virtualNetworks" = {
      non_technical = []
      technical     = ["Network Contributor"]
      solo_project  = ["Network Contributor"]
      admin         = ["Network Contributor"]
    }
  }
}

# ===================================================================
# TESTING AND VALIDATION
# ===================================================================

variable "enable_rbac_testing" {
  description = "Enable automated RBAC testing and validation"
  type        = bool
  default     = false
}

variable "test_users" {
  description = "Test user accounts for RBAC validation (for testing only)"
  type = map(object({
    object_id      = string
    user_type      = string
    environment    = string
    test_scenarios = list(string)
  }))
  default = {}
}

variable "rbac_validation_schedule" {
  description = "Cron schedule for automated RBAC validation (e.g., '0 2 * * 1' for weekly Monday 2 AM)"
  type        = string
  default     = "0 2 * * 1" # Weekly on Monday at 2 AM
}

# ===================================================================
# TENANT AND MANAGEMENT GROUP SUPPORT
# ===================================================================

variable "management_group_name" {
  description = "Name of the management group to assign roles at (optional)"
  type        = string
  default     = null
}

variable "tenant_id" {
  description = "Specific tenant ID to create tenant-level assignments (optional, defaults to current tenant)"
  type        = string
  default     = null
}

variable "enable_tenant_assignments" {
  description = "Enable role assignments at tenant level"
  type        = bool
  default     = false
}

variable "enable_management_group_assignments" {
  description = "Enable role assignments at management group level"
  type        = bool
  default     = true
}

# ===================================================================
# SERVICE PRINCIPAL MANAGEMENT
# ===================================================================

variable "service_principals" {
  description = "Service principals to create and assign roles to"
  type = map(object({
    display_name = string
    description  = string
    owners       = list(string)
    roles = map(object({
      scope = string
      role  = string
    }))
    tags = map(string)
  }))
  default = {}
}

variable "create_service_principals" {
  description = "Whether to create service principals as part of RBAC setup"
  type        = bool
  default     = false
}

variable "service_principal_password_rotation_days" {
  description = "Number of days before service principal passwords expire"
  type        = number
  default     = 365
}

# ===================================================================
# SUBSCRIPTION ISOLATION
# ===================================================================

variable "subscription_isolation" {
  description = "Enable separate state files for each subscription/environment combination"
  type        = bool
  default     = true
}

variable "state_backend_config" {
  description = "Backend configuration for Terraform state management"
  type = object({
    resource_group_name  = string
    storage_account_name = string
    container_name       = string
    key_prefix           = string
  })
  default = null
}