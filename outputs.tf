# RBAC Management Module Outputs

# ===================================================================
# AZURE AD GROUPS
# ===================================================================

output "organization_group" {
  description = "Organization root group information"
  value = {
    id           = azuread_group.organization.object_id
    display_name = azuread_group.organization.display_name
    description  = azuread_group.organization.description
  }
}

output "environment_groups" {
  description = "Environment groups information"
  value = {
    for key, group in azuread_group.environments : key => {
      id           = group.object_id
      display_name = group.display_name
      description  = group.description
      environment  = key
    }
  }
}

output "user_type_groups" {
  description = "User type groups information (non-technical, technical, solo-project, admin)"
  value = {
    for key, group in azuread_group.user_types : key => {
      id           = group.object_id
      display_name = group.display_name
      description  = group.description
      environment  = local.flattened_user_groups[key].environment
      user_type    = local.flattened_user_groups[key].user_type
    }
  }
}

output "project_groups" {
  description = "Project-specific groups information"
  value = {
    for key, group in azuread_group.projects : key => {
      id           = group.object_id
      display_name = group.display_name
      description  = group.description
      environment  = local.group_hierarchy.projects[key].environment
      user_type    = local.group_hierarchy.projects[key].user_type
      project      = local.group_hierarchy.projects[key].project
    }
  }
}

# ===================================================================
# GROUP HIERARCHY MAPPING
# ===================================================================

output "group_hierarchy" {
  description = "Complete group hierarchy structure"
  value = {
    organization = {
      id   = azuread_group.organization.object_id
      name = azuread_group.organization.display_name
      children = {
        for env_key, env_group in azuread_group.environments : env_key => {
          id   = env_group.object_id
          name = env_group.display_name
          children = {
            for ut_key, ut_group in azuread_group.user_types : ut_key => {
              id   = ut_group.object_id
              name = ut_group.display_name
              children = {
                for proj_key, proj_group in azuread_group.projects : proj_key => {
                  id   = proj_group.object_id
                  name = proj_group.display_name
                }
                if can(regex("^${env_key}-", proj_key))
              }
            }
            if can(regex("^${env_key}-", ut_key))
          }
        }
      }
    }
  }
}

# ===================================================================
# ROLE ASSIGNMENTS
# ===================================================================

output "subscription_role_assignments" {
  description = "Subscription-level role assignments summary"
  value = {
    for key, assignment in azurerm_role_assignment.subscription_individual_roles : key => {
      scope          = assignment.scope
      role           = assignment.role_definition_name
      principal_id   = assignment.principal_id
      principal_type = "Group"
    }
  }
}

output "resource_group_role_assignments" {
  description = "Resource group-level role assignments summary"
  value = {
    for key, assignment in azurerm_role_assignment.resource_group_assignments : key => {
      scope          = assignment.scope
      role           = assignment.role_definition_name
      principal_id   = assignment.principal_id
      principal_type = "Group"
    }
  }
}

output "management_group_role_assignments" {
  description = "Management group-level role assignments summary"
  value = {
    for key, assignment in azurerm_role_assignment.management_group_assignments : key => {
      scope          = assignment.scope
      role           = assignment.role_definition_name
      principal_id   = assignment.principal_id
      principal_type = "Group"
    }
  }
}

output "tenant_role_assignments" {
  description = "Tenant-level role assignments summary"
  value = {
    for key, assignment in azurerm_role_assignment.tenant_assignments : key => {
      scope          = assignment.scope
      role           = assignment.role_definition_name
      principal_id   = assignment.principal_id
      principal_type = "Group"
    }
  }
}

# ===================================================================
# SERVICE PRINCIPAL OUTPUTS
# ===================================================================

output "service_principals" {
  description = "Service principal information"
  value = {
    for key, sp in azuread_service_principal.service_principals : key => {
      id             = sp.id
      client_id      = sp.client_id
      display_name   = sp.display_name
      application_id = azuread_application.service_principals[key].id
    }
  }
  sensitive = true
}

output "service_principal_credentials" {
  description = "Service principal credentials (keep secure!)"
  value = {
    for key, cred in azuread_application_password.service_principal_passwords : key => {
      application_id = cred.application_id
      key_id         = cred.key_id
      end_date       = cred.end_date
      value          = cred.value
    }
  }
  sensitive = true
}

output "service_principal_role_assignments" {
  description = "Service principal role assignments summary"
  value = {
    for key, assignment in azurerm_role_assignment.service_principal_assignments : key => {
      scope          = assignment.scope
      role           = assignment.role_definition_name
      principal_id   = assignment.principal_id
      principal_type = "ServicePrincipal"
    }
  }
}

# ===================================================================
# RBAC SUMMARY BY ENVIRONMENT
# ===================================================================

output "rbac_summary_by_environment" {
  description = "RBAC configuration summary organized by environment"
  value = {
    for env in var.environments : env => {
      environment_group_id = azuread_group.environments[env].object_id
      user_types = {
        for user_type in ["non-technical", "technical", "solo-project", "admin"] : user_type => {
          group_id   = try(azuread_group.user_types["${env}-${user_type}"].object_id, null)
          group_name = try(azuread_group.user_types["${env}-${user_type}"].display_name, null)
          roles      = local.environment_roles[env][replace(user_type, "-", "_")]
        }
      }
      projects = var.create_project_groups ? {
        for proj in var.projects : proj => {
          for user_type in ["non-technical", "technical", "solo-project"] : "${proj}-${user_type}" => {
            group_id   = try(azuread_group.projects["${env}-${proj}-${user_type}"].object_id, null)
            group_name = try(azuread_group.projects["${env}-${proj}-${user_type}"].display_name, null)
          }
        }
      } : {}
    }
  }
}

# ===================================================================
# RBAC SUMMARY BY USER TYPE
# ===================================================================

output "rbac_summary_by_user_type" {
  description = "RBAC configuration summary organized by user type"
  value = {
    for user_type in ["non-technical", "technical", "solo-project", "admin"] : user_type => {
      environments = {
        for env in var.environments : env => {
          group_id   = try(azuread_group.user_types["${env}-${user_type}"].object_id, null)
          group_name = try(azuread_group.user_types["${env}-${user_type}"].display_name, null)
          roles      = local.environment_roles[env][replace(user_type, "-", "_")]

          # Resource-specific roles
          resource_roles = {
            for resource_type, roles_config in local.resource_roles : resource_type => {
              roles = roles_config[replace(user_type, "-", "_")]
            }
          }
        }
      }
    }
  }
}

# ===================================================================
# MANAGEMENT AND TROUBLESHOOTING
# ===================================================================

output "group_membership_commands" {
  description = "PowerShell commands to add users to groups"
  value = {
    for key, group in merge(azuread_group.user_types, azuread_group.projects) : key => {
      powershell_command = "Add-AzureADGroupMember -ObjectId '${group.object_id}' -RefObjectId '<USER_OBJECT_ID>'"
      azure_cli_command  = "az ad group member add --group '${group.object_id}' --member-id '<USER_OBJECT_ID>'"
      group_name         = group.display_name
    }
  }
}

output "role_assignment_validation" {
  description = "Commands to validate role assignments"
  value = {
    subscription_check = "Get-AzRoleAssignment -Scope '/subscriptions/${data.azurerm_client_config.current.subscription_id}' | Where-Object { $_.ObjectType -eq 'Group' }"
    resource_group_check = var.resource_groups != null ? {
      for rg_name, rg_data in var.resource_groups : rg_name => {
        command = "Get-AzRoleAssignment -Scope '${rg_data.id}' | Where-Object { $_.ObjectType -eq 'Group' }"
      }
    } : {}
  }
}

# ===================================================================
# GROUP OBJECT IDS FOR EXTERNAL USE
# ===================================================================

output "group_object_ids" {
  description = "All group object IDs for use in other modules"
  value = merge(
    {
      organization = azuread_group.organization.object_id
    },
    {
      for key, group in azuread_group.environments : "env-${key}" => group.object_id
    },
    {
      for key, group in azuread_group.user_types : "usertype-${key}" => group.object_id
    },
    {
      for key, group in azuread_group.projects : "project-${key}" => group.object_id
    }
  )
}

# ===================================================================
# SECURITY AND COMPLIANCE OUTPUTS
# ===================================================================

output "privileged_groups" {
  description = "Groups with privileged access that require additional monitoring"
  value = {
    for key, group in azuread_group.user_types : key => {
      group_id       = group.object_id
      group_name     = group.display_name
      user_type      = local.flattened_user_groups[key].user_type
      environment    = local.flattened_user_groups[key].environment
      is_privileged  = contains(["admin"], local.flattened_user_groups[key].user_type)
      assigned_roles = local.environment_roles[local.flattened_user_groups[key].environment][replace(local.flattened_user_groups[key].user_type, "-", "_")]
    }
  }
}

output "rbac_audit_info" {
  description = "Information for RBAC auditing and compliance"
  value = {
    total_groups_created               = length(azuread_group.organization) + length(azuread_group.environments) + length(azuread_group.user_types) + length(azuread_group.projects)
    environments_configured            = var.environments
    user_types_configured              = ["non-technical", "technical", "solo-project", "admin"]
    projects_configured                = var.projects
    subscription_assignments_enabled   = var.enable_subscription_assignments
    resource_group_assignments_enabled = var.enable_resource_group_assignments

    compliance_notes = {
      mfa_required_for_privileged = var.require_mfa_for_privileged_roles
      audit_retention_days        = var.audit_log_retention_days
      break_glass_accounts        = length(var.break_glass_accounts)
    }
  }
}