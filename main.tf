# Azure RBAC Multi-Level Management Module
# Comprehensive RBAC system with nested groups, environment separation,
# tenant and management group support, and service principal management

terraform {
  required_version = ">= 1.4.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80.0, < 5.0.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.30.0"
    }
  }
}

# Data sources
data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}

# Management Group data source (if management group is specified)
data "azurerm_management_group" "current" {
  count = var.management_group_name != null ? 1 : 0
  name  = var.management_group_name
}

# Tenant data source
data "azurerm_subscription" "current" {}

locals {
  # Environment-based role definitions
  environment_roles = {
    dev = {
      # Development environment - more permissive for testing
      non_technical = [
        "Reader",
        "Key Vault Secrets User"
      ]
      technical = [
        "Contributor",
        "Key Vault Administrator",
        "Storage Blob Data Contributor",
        "Log Analytics Reader"
      ]
      solo_project = [
        "Owner" # Full control in dev for solo projects
      ]
      admin = [
        "Owner",
        "User Access Administrator"
      ]
    }

    test = {
      # Test environment - controlled access
      non_technical = [
        "Reader",
        "Key Vault Secrets User"
      ]
      technical = [
        "Reader",
        "Virtual Machine Contributor",
        "Storage Blob Data Reader",
        "Key Vault Secrets User",
        "Log Analytics Reader"
      ]
      solo_project = [
        "Contributor"
      ]
      admin = [
        "Owner",
        "User Access Administrator"
      ]
    }

    prod = {
      # Production environment - strict access control
      non_technical = [
        "Reader"
      ]
      technical = [
        "Reader",
        "Monitoring Reader",
        "Log Analytics Reader"
      ]
      solo_project = [
        "Reader" # Very limited in production
      ]
      admin = [
        "Contributor", # No Owner in prod except break-glass
        "Key Vault Administrator",
        "User Access Administrator"
      ]
    }
  }

  # Resource-specific role mappings
  resource_roles = {
    key_vault = {
      non_technical = ["Key Vault Secrets User"]
      technical     = ["Key Vault Administrator", "Key Vault Secrets Officer"]
      solo_project  = ["Key Vault Administrator"]
      admin         = ["Key Vault Administrator"]
    }

    storage = {
      non_technical = ["Storage Blob Data Reader"]
      technical     = ["Storage Blob Data Contributor", "Storage Account Contributor"]
      solo_project  = ["Storage Blob Data Owner"]
      admin         = ["Storage Account Contributor"]
    }

    networking = {
      non_technical = [] # No network access for non-technical
      technical     = ["Network Contributor"]
      solo_project  = ["Network Contributor"]
      admin         = ["Network Contributor"]
    }

    compute = {
      non_technical = ["Virtual Machine User Login"]
      technical     = ["Virtual Machine Contributor"]
      solo_project  = ["Virtual Machine Contributor"]
      admin         = ["Virtual Machine Contributor"]
    }

    database = {
      non_technical = ["SQL DB Contributor"]
      technical     = ["SQL DB Contributor", "SQL Server Contributor"]
      solo_project  = ["SQL DB Contributor"]
      admin         = ["SQL Server Contributor"]
    }

    monitoring = {
      non_technical = ["Monitoring Reader"]
      technical     = ["Monitoring Contributor", "Log Analytics Reader"]
      solo_project  = ["Monitoring Contributor"]
      admin         = ["Monitoring Contributor", "Log Analytics Contributor"]
    }
  }

  # Group hierarchy structure
  group_hierarchy = {
    # Root organizational groups
    organization = {
      name_pattern = "${var.organization_prefix}-org"
      description  = "Root organizational group"
    }

    # Environment-level groups (children of organization)
    environments = {
      for env in var.environments : env => {
        name_pattern = "${var.organization_prefix}-${env}"
        description  = "Environment group for ${env}"
        parent       = "organization"
      }
    }

    # User type groups (children of environment groups)
    user_types = {
      for env in var.environments : env => {
        for user_type in ["non-technical", "technical", "solo-project", "admin"] : "${env}-${user_type}" => {
          name_pattern = "${var.organization_prefix}-${env}-${user_type}"
          description  = "${title(replace(user_type, "-", " "))} users for ${env} environment"
          parent       = env
          user_type    = user_type
          environment  = env
        }
      }
    }

    # Project-specific groups (children of user type groups)
    projects = var.create_project_groups ? {
      for combo in setproduct(var.environments, var.projects, ["non-technical", "technical", "solo-project"]) :
      "${combo[0]}-${combo[1]}-${combo[2]}" => {
        name_pattern = "${var.organization_prefix}-${combo[0]}-${combo[1]}-${combo[2]}"
        description  = "${title(replace(combo[2], "-", " "))} users for project ${combo[1]} in ${combo[0]}"
        parent       = "${combo[0]}-${combo[2]}"
        user_type    = combo[2]
        environment  = combo[0]
        project      = combo[1]
      }
    } : {}
  }

  # Flatten user type groups for easier processing
  flattened_user_groups = merge([
    for env_key, user_types in local.group_hierarchy.user_types : user_types
  ]...)

  # Role assignments matrix
  role_assignments = {
    # Management group-level assignments
    management_group = var.management_group_name != null ? {
      for key, group in local.flattened_user_groups : key => {
        group_name  = group.name_pattern
        roles       = local.environment_roles[group.environment][replace(group.user_type, "-", "_")]
        scope       = data.azurerm_management_group.current[0].id
        environment = group.environment
        user_type   = group.user_type
      }
    } : {}

    # Tenant-level assignments
    tenant = var.enable_tenant_assignments ? {
      for key, group in local.flattened_user_groups : key => {
        group_name  = group.name_pattern
        roles       = local.environment_roles[group.environment][replace(group.user_type, "-", "_")]
        scope       = "/providers/Microsoft.Management/managementGroups/${var.tenant_id != null ? var.tenant_id : data.azurerm_client_config.current.tenant_id}"
        environment = group.environment
        user_type   = group.user_type
      }
    } : {}

    # Subscription-level assignments
    subscription = {
      for key, group in local.flattened_user_groups : key => {
        group_name  = group.name_pattern
        roles       = local.environment_roles[group.environment][replace(group.user_type, "-", "_")]
        scope       = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
        environment = group.environment
        user_type   = group.user_type
      }
    }

    # Resource group-level assignments (if resource groups are provided)
    resource_group = var.resource_groups != null ? {
      for rg_combo in setproduct(keys(var.resource_groups), keys(local.flattened_user_groups)) :
      "${rg_combo[0]}-${rg_combo[1]}" => {
        resource_group = rg_combo[0]
        group_key      = rg_combo[1]
        group_name     = local.flattened_user_groups[rg_combo[1]].name_pattern
        roles          = local.environment_roles[local.flattened_user_groups[rg_combo[1]].environment][replace(local.flattened_user_groups[rg_combo[1]].user_type, "-", "_")]
        scope          = var.resource_groups[rg_combo[0]].id
        environment    = local.flattened_user_groups[rg_combo[1]].environment
        user_type      = local.flattened_user_groups[rg_combo[1]].user_type
      }
    } : {}
  }
}

# ===================================================================
# AZURE AD GROUPS CREATION
# ===================================================================

# Organization root group
resource "azuread_group" "organization" {
  display_name            = local.group_hierarchy.organization.name_pattern
  description             = local.group_hierarchy.organization.description
  security_enabled        = true
  assignable_to_role      = true
  prevent_duplicate_names = true

  dynamic "owners" {
    for_each = var.group_owners
    content {
      object_id = owners.value
    }
  }
}

# Environment groups
resource "azuread_group" "environments" {
  for_each = local.group_hierarchy.environments

  display_name            = each.value.name_pattern
  description             = each.value.description
  security_enabled        = true
  assignable_to_role      = true
  prevent_duplicate_names = true

  dynamic "owners" {
    for_each = var.group_owners
    content {
      object_id = owners.value
    }
  }

  # Add environment groups as members of organization group
  depends_on = [azuread_group.organization]
}

# Add environment groups to organization group
resource "azuread_group_member" "environment_to_org" {
  for_each = local.group_hierarchy.environments

  group_object_id  = azuread_group.organization.object_id
  member_object_id = azuread_group.environments[each.key].object_id
}

# User type groups (non-technical, technical, solo-project, admin)
resource "azuread_group" "user_types" {
  for_each = local.flattened_user_groups

  display_name            = each.value.name_pattern
  description             = each.value.description
  security_enabled        = true
  assignable_to_role      = true
  prevent_duplicate_names = true

  dynamic "owners" {
    for_each = var.group_owners
    content {
      object_id = owners.value
    }
  }

  depends_on = [azuread_group.environments]
}

# Add user type groups to environment groups
resource "azuread_group_member" "user_types_to_env" {
  for_each = local.flattened_user_groups

  group_object_id  = azuread_group.environments[each.value.environment].object_id
  member_object_id = azuread_group.user_types[each.key].object_id
}

# Project-specific groups (optional)
resource "azuread_group" "projects" {
  for_each = local.group_hierarchy.projects

  display_name            = each.value.name_pattern
  description             = each.value.description
  security_enabled        = true
  assignable_to_role      = true
  prevent_duplicate_names = true

  dynamic "owners" {
    for_each = var.group_owners
    content {
      object_id = owners.value
    }
  }

  depends_on = [azuread_group.user_types]
}

# Add project groups to user type groups
resource "azuread_group_member" "projects_to_user_types" {
  for_each = local.group_hierarchy.projects

  group_object_id  = azuread_group.user_types[each.value.parent].object_id
  member_object_id = azuread_group.projects[each.key].object_id
}

# ===================================================================
# SERVICE PRINCIPAL MANAGEMENT
# ===================================================================

resource "azuread_application" "service_principals" {
  for_each = var.service_principals

  display_name = each.value.display_name
  description  = each.value.description

  tags = each.value.tags
}

resource "azuread_service_principal" "service_principals" {
  for_each = var.service_principals

  client_id = azuread_application.service_principals[each.key].client_id

  tags = each.value.tags
}

resource "azuread_application_password" "service_principal_passwords" {
  for_each = var.service_principals

  application_id = azuread_application.service_principals[each.key].id
  end_date       = timeadd(timestamp(), "${var.service_principal_password_rotation_days * 24}h")
}

resource "azuread_app_role_assignment" "service_principal_owners" {
  for_each = {
    for sp_owner in flatten([
      for sp_key, sp in var.service_principals : [
        for owner_id in sp.owners : {
          key      = "${sp_key}-${owner_id}"
          sp_key   = sp_key
          owner_id = owner_id
        }
      ]
    ]) : sp_owner.key => sp_owner
  }

  app_role_id         = azuread_service_principal.service_principals[each.value.sp_key].object_id
  principal_object_id = each.value.owner_id
  resource_object_id  = azuread_application.service_principals[each.value.sp_key].object_id
}

# Service Principal Role Assignments
resource "azurerm_role_assignment" "service_principal_assignments" {
  for_each = {
    for sp_role in flatten([
      for sp_key, sp in var.service_principals : [
        for role_key, role in sp.roles : {
          key    = "${sp_key}-${role_key}"
          sp_key = sp_key
          scope  = role.scope
          role   = role.role
        }
      ]
    ]) : sp_role.key => sp_role
  }

  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = azuread_service_principal.service_principals[each.value.sp_key].object_id
}

# ===================================================================
# SUBSCRIPTION-LEVEL ROLE ASSIGNMENTS
# ===================================================================

resource "azurerm_role_assignment" "subscription_assignments" {
  for_each = {
    for assignment_key, assignment in local.role_assignments.subscription : assignment_key => assignment
    if var.enable_subscription_assignments
  }

  scope                = each.value.scope
  role_definition_name = join(",", each.value.roles) # This will need to be handled per role
  principal_id         = azuread_group.user_types[each.key].object_id

  depends_on = [azuread_group.user_types]
}

# Individual role assignments (since Azure doesn't support multiple roles in one assignment)
resource "azurerm_role_assignment" "subscription_individual_roles" {
  for_each = {
    for assignment in flatten([
      for group_key, assignment in local.role_assignments.subscription : [
        for role in assignment.roles : {
          key       = "${group_key}-${role}"
          group_key = group_key
          role      = role
          scope     = assignment.scope
        }
      ]
    ]) : assignment.key => assignment
    if var.enable_subscription_assignments
  }

  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = azuread_group.user_types[each.value.group_key].object_id

  depends_on = [azuread_group.user_types]
}

# ===================================================================
# RESOURCE GROUP-LEVEL ROLE ASSIGNMENTS
# ===================================================================

resource "azurerm_role_assignment" "resource_group_assignments" {
  for_each = {
    for assignment in flatten([
      for rg_assignment_key, rg_assignment in local.role_assignments.resource_group : [
        for role in rg_assignment.roles : {
          key            = "${rg_assignment_key}-${role}"
          group_key      = rg_assignment.group_key
          role           = role
          scope          = rg_assignment.scope
          resource_group = rg_assignment.resource_group
        }
      ]
    ]) : assignment.key => assignment
    if var.enable_resource_group_assignments && var.resource_groups != null
  }

  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = azuread_group.user_types[each.value.group_key].object_id

  depends_on = [azuread_group.user_types]
}

# ===================================================================
# MANAGEMENT GROUP-LEVEL ROLE ASSIGNMENTS
# ===================================================================

resource "azurerm_role_assignment" "management_group_assignments" {
  for_each = {
    for assignment in flatten([
      for group_key, assignment in local.role_assignments.management_group : [
        for role in assignment.roles : {
          key       = "${group_key}-${role}"
          group_key = group_key
          role      = role
          scope     = assignment.scope
        }
      ]
    ]) : assignment.key => assignment
    if var.enable_management_group_assignments && var.management_group_name != null
  }

  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = azuread_group.user_types[each.value.group_key].object_id

  depends_on = [azuread_group.user_types]
}

# ===================================================================
# TENANT-LEVEL ROLE ASSIGNMENTS
# ===================================================================

resource "azurerm_role_assignment" "tenant_assignments" {
  for_each = {
    for assignment in flatten([
      for group_key, assignment in local.role_assignments.tenant : [
        for role in assignment.roles : {
          key       = "${group_key}-${role}"
          group_key = group_key
          role      = role
          scope     = assignment.scope
        }
      ]
    ]) : assignment.key => assignment
    if var.enable_tenant_assignments
  }

  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = azuread_group.user_types[each.value.group_key].object_id

  depends_on = [azuread_group.user_types]
}