<p align="center">
  <a href="https://aircloud.com.pl"><img src=".github/assets/banner.png" alt="AIRCLOUD: DevOps, cloud and AI engineering" width="100%"></a>
</p>

# azure-rbac-management

**RBAC management module for Azure infrastructure with enterprise-grade security.**

[![CI](https://github.com/AIRCLOUD-PL/azure-rbac-management/actions/workflows/ci.yml/badge.svg)](https://github.com/AIRCLOUD-PL/azure-rbac-management/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/AIRCLOUD-PL/azure-rbac-management?sort=semver)](https://github.com/AIRCLOUD-PL/azure-rbac-management/releases)

This system implements a sophisticated Role-Based Access Control (RBAC) solution for Azure environments with support for:

- **Multi-level group hierarchy** with nested Azure AD groups
- **Environment separation** (dev, test, prod) with appropriate permissions
- **User type segregation** (non-technical, technical, solo-project, admin)
- **Project-based isolation** with dedicated resource access
- **Compliance-ready** with audit trails and security controls

## Usage

Pin the module to a release tag:

```hcl
module "rbac_management" {
  source = "git::https://github.com/AIRCLOUD-PL/azure-rbac-management.git?ref=v1.0.0"

  # required inputs
  group_owners        = []
  organization_prefix = "..."
}
```

All inputs and outputs are listed in the generated reference below ([Inputs](#inputs), [Outputs](#outputs)). Worked examples live in [`examples/`](examples/).

## 🏗️ Architecture Overview

### Group Hierarchy Structure

```
Organization Root Group (aircloud-org)
├── Environment Groups
│   ├── aircloud-dev
│   │   ├── aircloud-dev-non-technical
│   │   ├── aircloud-dev-technical  
│   │   ├── aircloud-dev-solo-project
│   │   └── aircloud-dev-admin
│   ├── aircloud-test
│   │   ├── aircloud-test-non-technical
│   │   ├── aircloud-test-technical
│   │   ├── aircloud-test-solo-project
│   │   └── aircloud-test-admin
│   └── aircloud-prod
│       ├── aircloud-prod-non-technical
│       ├── aircloud-prod-technical
│       ├── aircloud-prod-solo-project
│       └── aircloud-prod-admin
└── Project Groups (Optional)
    ├── aircloud-dev-project-alpha-technical
    ├── aircloud-dev-project-alpha-solo-project
    ├── aircloud-prod-project-beta-technical
    └── ...
```

## 👥 User Types and Permissions

### 1. Non-Technical Users
**Purpose**: Business users, analysts, auditors, managers
**Typical Roles**: Business analysts, project managers, compliance officers

#### Environment-Specific Permissions:
- **Development**: 
  - `Reader` - View all resources
  - `Key Vault Secrets User` - Access application secrets
- **Test**: 
  - `Reader` - View resources
  - `Key Vault Secrets User` - Access test data
- **Production**: 
  - `Reader` - View-only access (highly restricted)

#### Resource-Specific Access:
- **Key Vault**: Secrets User (read-only)
- **Storage**: Blob Data Reader
- **Monitoring**: Reader access to dashboards
- **Networking**: No access (security restriction)

### 2. Technical Users  
**Purpose**: Developers, DevOps engineers, system integrators
**Typical Roles**: Software developers, DevOps engineers, cloud architects

#### Environment-Specific Permissions:
- **Development**:
  - `Contributor` - Create/modify resources
  - `Key Vault Administrator` - Manage secrets
  - `Storage Blob Data Contributor` - Read/write data
  - `Log Analytics Reader` - Access logs
- **Test**:
  - `Reader` - View resources
  - `Virtual Machine Contributor` - Manage test VMs
  - `Storage Blob Data Reader` - Read test data
  - `Key Vault Secrets User` - Access test secrets
- **Production**:
  - `Reader` - View-only access
  - `Monitoring Reader` - View production metrics
  - `Log Analytics Reader` - Troubleshooting access

### 3. Solo Project Users
**Purpose**: Independent contractors, consultants, temporary project members
**Typical Roles**: External consultants, freelance developers, temporary staff

#### Environment-Specific Permissions:
- **Development**:
  - `Owner` - Full control within project scope
- **Test**:
  - `Contributor` - Manage project resources
- **Production**:
  - `Reader` - Very limited access (security policy)

#### Special Characteristics:
- Resource spending limits ($5,000/month default)
- Isolated project environments
- No cross-project access
- Automatic access expiration

### 4. Admin Users
**Purpose**: System administrators, security team, platform engineers
**Typical Roles**: Cloud administrators, security engineers, platform team

#### Environment-Specific Permissions:
- **Development**:
  - `Owner` - Full administrative control
  - `User Access Administrator` - Manage RBAC
- **Test**:
  - `Owner` - Full administrative control
  - `User Access Administrator` - Manage RBAC
- **Production**:
  - `Contributor` - Operational control (no Owner for security)
  - `Key Vault Administrator` - Manage production secrets
  - `User Access Administrator` - Manage emergency access

## 🌍 Environment-Specific Security Policies

### Development Environment
- **Philosophy**: Innovation and experimentation friendly
- **Access Level**: Permissive for faster development
- **Security**: Basic controls, auto-cleanup enabled
- **Monitoring**: Development-focused metrics
- **Cost Control**: Auto-shutdown, resource quotas

### Test Environment  
- **Philosophy**: Production-like for realistic testing
- **Access Level**: Controlled access for validation
- **Security**: Enhanced security with private endpoints
- **Monitoring**: Comprehensive monitoring with alerting
- **Cost Control**: Balanced optimization

### Production Environment
- **Philosophy**: Maximum security and reliability
- **Access Level**: Strict access control, all changes audited
- **Security**: Full security stack (firewall, private endpoints, encryption)
- **Monitoring**: Complete observability with 24/7 alerting
- **Cost Control**: Long-term retention, no auto-shutdown

## 🔐 Security Features

### Break-Glass Access
Emergency access accounts for critical situations:
- Pre-approved emergency accounts
- Automatic audit trail
- Time-limited access (4-hour sessions)
- Multi-person approval required
- Immediate security team notification

### Compliance Controls
- **SOC 2**: Separation of duties, access reviews
- **ISO 27001**: Comprehensive access controls
- **HIPAA**: Healthcare data protection (if applicable)
- **PCI DSS**: Financial data security controls
- **GDPR**: Data privacy and access logging

### Security Monitoring
- All RBAC changes logged to Azure Monitor
- Privileged access monitoring
- Anomaly detection for unusual access patterns
- Monthly access reviews and cleanup
- Integration with Azure AD Privileged Identity Management (PIM)

## 📋 Usage Examples

### Basic Implementation
```hcl
module "rbac" {
  source = "git::https://github.com/AIRCLOUD-PL/azure-rbac-management.git?ref=v1.0.0"
  
  organization_prefix = "mycompany"
  environments       = ["dev", "test", "prod"]
  projects          = ["web-app", "mobile-app", "data-platform"]
  create_project_groups = true
  
  group_owners = ["admin@mycompany.com"]
  
  enable_subscription_assignments    = true
  enable_resource_group_assignments = true
}
```

### Adding Users to Groups
```powershell
# Add a developer to technical users group
Add-AzureADGroupMember -ObjectId "group-object-id" -RefObjectId "user-object-id"

# Add business analyst to non-technical users group  
Add-AzureADGroupMember -ObjectId "group-object-id" -RefObjectId "user-object-id"
```

### Resource Group Integration
```hcl
resource "azurerm_resource_group" "example" {
  name     = "rg-myapp-prod"
  location = "East US"
  tags = {
    Environment = "prod"
    CriticalityLevel = "high"
  }
}

# Automatic RBAC assignment based on resource group environment and criticality
```

## 🧪 Testing and Validation

### Automated Tests
The system includes comprehensive automated tests:

```bash
# Run RBAC validation tests
cd tests/rbac-tests
terraform test

# Run specific test scenarios
terraform test -filter="group_creation"
terraform test -filter="role_assignments"  
terraform test -filter="security_validation"
```

### Test Categories:
1. **Group Creation Tests**: Verify all groups are created correctly
2. **Hierarchy Tests**: Validate parent-child relationships
3. **Role Assignment Tests**: Confirm correct permissions
4. **Environment Separation Tests**: Ensure environment isolation
5. **Security Tests**: Validate compliance and security controls
6. **Performance Tests**: Check system responsiveness
7. **Integration Tests**: Test with actual Azure resources

### Manual Validation
```powershell
# Check group membership
Get-AzureADGroupMember -ObjectId "group-object-id"

# Validate role assignments
Get-AzRoleAssignment -Scope "/subscriptions/subscription-id" | Where-Object { $_.ObjectType -eq "Group" }

# Test access permissions
Test-AzRoleAssignment -PrincipalId "user-id" -RoleDefinitionName "Contributor" -Scope "/subscriptions/subscription-id"
```

## 📊 Monitoring and Reporting

### Built-in Reports
- Monthly access review reports
- Privileged access usage statistics  
- Compliance posture dashboard
- Cost attribution by user type
- Security incident correlation

### Audit Queries (KQL)
```kql
// Track RBAC changes
AuditLogs
| where Category == "RoleManagement"
| where TimeGenerated > ago(30d)
| project TimeGenerated, Identity, OperationName, Result

// Monitor privileged access usage
SigninLogs
| where UserPrincipalName has "admin"
| where TimeGenerated > ago(7d)
| summarize count() by UserPrincipalName, AppDisplayName
```

## 🚀 Deployment Guide

### Prerequisites
1. Azure subscription with Owner rights
2. Azure AD tenant with Global Administrator rights
3. Terraform >= 1.3.0
4. Azure CLI or PowerShell with appropriate modules

### Step-by-Step Deployment

1. **Configure Environment**
```bash
# Set Azure subscription
az account set --subscription "your-subscription-id"

# Verify permissions
az ad signed-in-user show --query "[id,userPrincipalName]"
```

2. **Deploy Multi-Tenant Configuration**
```hcl
module "config" {
  source = "git::https://github.com/AIRCLOUD-PL/azure-multi-tenant-config.git?ref=v1.0.0"
  
  environment    = "prod"
  project_name   = "platform"
  organization   = "yourorg"
}
```

3. **Deploy RBAC System**
```hcl
module "rbac" {
  source = "git::https://github.com/AIRCLOUD-PL/azure-rbac-management.git?ref=v1.0.0"
  
  organization_prefix = "yourorg"
  environments       = ["dev", "test", "prod"]
  group_owners       = [data.azurerm_client_config.current.object_id]
}
```

4. **Validate Deployment**
```bash
terraform test -filter="rbac"
```

### Post-Deployment Tasks
1. Add initial users to appropriate groups
2. Configure conditional access policies
3. Set up monitoring and alerting
4. Schedule regular access reviews
5. Document emergency procedures

## 🔧 Customization Options

### Custom Roles
Define organization-specific roles:
```hcl
custom_role_definitions = {
  "DataScientist" = {
    role_name    = "Data Scientist"
    description  = "Access to ML and analytics resources"
    permissions  = ["Microsoft.MachineLearningServices/*"]
    environments = ["dev", "test"]
    user_types   = ["technical"]
  }
}
```

### Environment Overrides
Customize permissions per environment:
```hcl
environment_specific_roles = {
  prod = {
    technical = ["Security Reader", "Monitoring Contributor"]
    admin     = ["Security Administrator"]
  }
}
```

### Integration Settings
```hcl
# Enable PIM integration
integrate_with_pim = true

# Enable conditional access
integrate_with_conditional_access = true

# Custom audit retention
audit_log_retention_days = 2555  # 7 years
```

## 📞 Support and Troubleshooting

### Common Issues

1. **Group Creation Failures**
   - Verify Azure AD permissions
   - Check naming convention limits
   - Ensure unique group names

2. **Role Assignment Errors** 
   - Confirm subscription permissions
   - Validate resource group existence
   - Check role definition availability

3. **Test Failures**
   - Review test resource quotas
   - Verify service principal permissions
   - Check Azure AD token expiration

### Getting Help
- Review module documentation in `modules/rbac-management/README.md`
- Check example implementations in `examples/`
- Run diagnostic tests: `terraform test -verbose`
- Enable debug logging: `TF_LOG=DEBUG terraform apply`

## 📄 License

This RBAC system is part of the AIRCLOUD Azure Infrastructure Platform.

---

**⚠️ Important Security Notice**: This system manages critical security permissions. Always test in non-production environments first and follow your organization's change management procedures.

## Reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | ~> 3.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | 3.10.0 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.81.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azuread_app_role_assignment.service_principal_owners](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/app_role_assignment) | resource |
| [azuread_application.service_principals](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application) | resource |
| [azuread_application_password.service_principal_passwords](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_password) | resource |
| [azuread_group.environments](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/group) | resource |
| [azuread_group.organization](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/group) | resource |
| [azuread_group.projects](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/group) | resource |
| [azuread_group.user_types](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/group) | resource |
| [azuread_group_member.environment_to_org](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/group_member) | resource |
| [azuread_group_member.projects_to_user_types](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/group_member) | resource |
| [azuread_group_member.user_types_to_env](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/group_member) | resource |
| [azuread_service_principal.service_principals](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) | resource |
| [azurerm_role_assignment.management_group_assignments](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.resource_group_assignments](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.service_principal_assignments](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.subscription_assignments](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.subscription_individual_roles](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.tenant_assignments](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azuread_client_config.current](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/client_config) | data source |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_management_group.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/management_group) | data source |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_user_settings"></a> [admin\_user\_settings](#input\_admin\_user\_settings) | Specific settings for admin users | <pre>object({<br/>    max_role_assignments      = optional(number, 50)<br/>    allowed_resource_types    = optional(list(string), ["*"])<br/>    require_approval_for_prod = optional(bool, false)<br/>    default_access_duration   = optional(string, "permanent")<br/>    can_manage_rbac           = optional(bool, true)<br/>    emergency_access_enabled  = optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_audit_log_retention_days"></a> [audit\_log\_retention\_days](#input\_audit\_log\_retention\_days) | Number of days to retain RBAC change audit logs | `number` | `365` | no |
| <a name="input_break_glass_accounts"></a> [break\_glass\_accounts](#input\_break\_glass\_accounts) | Break glass accounts that get emergency access in production | <pre>map(object({<br/>    object_id    = string<br/>    display_name = string<br/>    roles        = list(string)<br/>    environments = list(string) # Which environments this applies to<br/>  }))</pre> | `{}` | no |
| <a name="input_create_project_groups"></a> [create\_project\_groups](#input\_create\_project\_groups) | Whether to create project-specific groups in addition to environment groups | `bool` | `false` | no |
| <a name="input_create_service_principals"></a> [create\_service\_principals](#input\_create\_service\_principals) | Whether to create service principals as part of RBAC setup | `bool` | `false` | no |
| <a name="input_custom_role_definitions"></a> [custom\_role\_definitions](#input\_custom\_role\_definitions) | Custom role definitions for specific needs | <pre>map(object({<br/>    role_name    = string<br/>    description  = string<br/>    permissions  = list(string)<br/>    environments = list(string) # Which environments this role applies to<br/>    user_types   = list(string) # Which user types can have this role<br/>  }))</pre> | `{}` | no |
| <a name="input_custom_scopes"></a> [custom\_scopes](#input\_custom\_scopes) | Additional custom scopes for role assignments (e.g., specific resources) | <pre>map(object({<br/>    scope       = string<br/>    description = string<br/>    environment = string<br/>  }))</pre> | `{}` | no |
| <a name="input_default_group_owners"></a> [default\_group\_owners](#input\_default\_group\_owners) | Default owners to add to all groups (in addition to group\_owners) | `list(string)` | `[]` | no |
| <a name="input_enable_custom_scope_assignments"></a> [enable\_custom\_scope\_assignments](#input\_enable\_custom\_scope\_assignments) | Enable role assignments at custom scopes | `bool` | `false` | no |
| <a name="input_enable_management_group_assignments"></a> [enable\_management\_group\_assignments](#input\_enable\_management\_group\_assignments) | Enable role assignments at management group level | `bool` | `true` | no |
| <a name="input_enable_rbac_testing"></a> [enable\_rbac\_testing](#input\_enable\_rbac\_testing) | Enable automated RBAC testing and validation | `bool` | `false` | no |
| <a name="input_enable_resource_group_assignments"></a> [enable\_resource\_group\_assignments](#input\_enable\_resource\_group\_assignments) | Enable role assignments at resource group level | `bool` | `true` | no |
| <a name="input_enable_subscription_assignments"></a> [enable\_subscription\_assignments](#input\_enable\_subscription\_assignments) | Enable role assignments at subscription level | `bool` | `true` | no |
| <a name="input_enable_tenant_assignments"></a> [enable\_tenant\_assignments](#input\_enable\_tenant\_assignments) | Enable role assignments at tenant level | `bool` | `false` | no |
| <a name="input_environment_specific_roles"></a> [environment\_specific\_roles](#input\_environment\_specific\_roles) | Additional roles for specific environments beyond defaults | <pre>map(object({<br/>    non_technical = optional(list(string), [])<br/>    technical     = optional(list(string), [])<br/>    solo_project  = optional(list(string), [])<br/>    admin         = optional(list(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_environments"></a> [environments](#input\_environments) | List of environments to create RBAC groups for | `list(string)` | <pre>[<br/>  "dev",<br/>  "test",<br/>  "prod"<br/>]</pre> | no |
| <a name="input_group_owners"></a> [group\_owners](#input\_group\_owners) | List of object IDs that will be owners of created Azure AD groups | `list(string)` | n/a | yes |
| <a name="input_integrate_with_conditional_access"></a> [integrate\_with\_conditional\_access](#input\_integrate\_with\_conditional\_access) | Create conditional access policies for RBAC groups | `bool` | `false` | no |
| <a name="input_integrate_with_pim"></a> [integrate\_with\_pim](#input\_integrate\_with\_pim) | Integrate with Azure AD Privileged Identity Management | `bool` | `false` | no |
| <a name="input_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#input\_log\_analytics\_workspace\_id) | Log Analytics workspace ID for RBAC audit logging | `string` | `null` | no |
| <a name="input_management_group_name"></a> [management\_group\_name](#input\_management\_group\_name) | Name of the management group to assign roles at (optional) | `string` | `null` | no |
| <a name="input_non_technical_user_settings"></a> [non\_technical\_user\_settings](#input\_non\_technical\_user\_settings) | Specific settings for non-technical users | <pre>object({<br/>    max_role_assignments      = optional(number, 5)<br/>    allowed_resource_types    = optional(list(string), ["Microsoft.KeyVault/vaults", "Microsoft.Storage/storageAccounts"])<br/>    require_approval_for_prod = optional(bool, true)<br/>    default_access_duration   = optional(string, "8h") # For Just-In-Time access<br/>  })</pre> | `{}` | no |
| <a name="input_notification_email"></a> [notification\_email](#input\_notification\_email) | Email address for RBAC change notifications | `string` | `null` | no |
| <a name="input_organization_prefix"></a> [organization\_prefix](#input\_organization\_prefix) | Organization prefix for group naming (e.g., 'aircloud', 'company') | `string` | n/a | yes |
| <a name="input_privileged_roles"></a> [privileged\_roles](#input\_privileged\_roles) | List of roles considered privileged (requiring additional security) | `list(string)` | <pre>[<br/>  "Owner",<br/>  "Contributor",<br/>  "User Access Administrator",<br/>  "Security Administrator",<br/>  "Key Vault Administrator"<br/>]</pre> | no |
| <a name="input_projects"></a> [projects](#input\_projects) | List of projects to create project-specific RBAC groups for (optional) | `list(string)` | `[]` | no |
| <a name="input_rbac_validation_schedule"></a> [rbac\_validation\_schedule](#input\_rbac\_validation\_schedule) | Cron schedule for automated RBAC validation (e.g., '0 2 * * 1' for weekly Monday 2 AM) | `string` | `"0 2 * * 1"` | no |
| <a name="input_require_mfa_for_privileged_roles"></a> [require\_mfa\_for\_privileged\_roles](#input\_require\_mfa\_for\_privileged\_roles) | Require MFA for privileged roles (Owner, Contributor, etc.) | `bool` | `true` | no |
| <a name="input_resource_groups"></a> [resource\_groups](#input\_resource\_groups) | Map of resource groups to assign permissions to. Key is RG name, value contains RG details. | <pre>map(object({<br/>    id                = string<br/>    name              = string<br/>    environment       = string<br/>    resource_types    = optional(list(string), []) # Types of resources in this RG<br/>    criticality_level = optional(string, "medium") # low, medium, high, critical<br/>  }))</pre> | `null` | no |
| <a name="input_resource_type_role_mappings"></a> [resource\_type\_role\_mappings](#input\_resource\_type\_role\_mappings) | Custom role mappings for specific resource types | <pre>map(object({<br/>    non_technical = list(string)<br/>    technical     = list(string)<br/>    solo_project  = list(string)<br/>    admin         = list(string)<br/>  }))</pre> | <pre>{<br/>  "Microsoft.Compute/virtualMachines": {<br/>    "admin": [<br/>      "Virtual Machine Contributor"<br/>    ],<br/>    "non_technical": [<br/>      "Virtual Machine User Login"<br/>    ],<br/>    "solo_project": [<br/>      "Virtual Machine Contributor"<br/>    ],<br/>    "technical": [<br/>      "Virtual Machine Contributor"<br/>    ]<br/>  },<br/>  "Microsoft.KeyVault/vaults": {<br/>    "admin": [<br/>      "Key Vault Administrator"<br/>    ],<br/>    "non_technical": [<br/>      "Key Vault Secrets User"<br/>    ],<br/>    "solo_project": [<br/>      "Key Vault Administrator"<br/>    ],<br/>    "technical": [<br/>      "Key Vault Administrator",<br/>      "Key Vault Secrets Officer"<br/>    ]<br/>  },<br/>  "Microsoft.Network/virtualNetworks": {<br/>    "admin": [<br/>      "Network Contributor"<br/>    ],<br/>    "non_technical": [],<br/>    "solo_project": [<br/>      "Network Contributor"<br/>    ],<br/>    "technical": [<br/>      "Network Contributor"<br/>    ]<br/>  },<br/>  "Microsoft.Storage/storageAccounts": {<br/>    "admin": [<br/>      "Storage Account Contributor"<br/>    ],<br/>    "non_technical": [<br/>      "Storage Blob Data Reader"<br/>    ],<br/>    "solo_project": [<br/>      "Storage Blob Data Owner"<br/>    ],<br/>    "technical": [<br/>      "Storage Blob Data Contributor",<br/>      "Storage Account Contributor"<br/>    ]<br/>  }<br/>}</pre> | no |
| <a name="input_role_overrides"></a> [role\_overrides](#input\_role\_overrides) | Override default roles for specific environment/user type combinations | <pre>map(object({<br/>    environment = string<br/>    user_type   = string<br/>    roles       = list(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_service_principal_password_rotation_days"></a> [service\_principal\_password\_rotation\_days](#input\_service\_principal\_password\_rotation\_days) | Number of days before service principal passwords expire | `number` | `365` | no |
| <a name="input_service_principals"></a> [service\_principals](#input\_service\_principals) | Service principals to create and assign roles to | <pre>map(object({<br/>    display_name = string<br/>    description  = string<br/>    owners       = list(string)<br/>    roles = map(object({<br/>      scope = string<br/>      role  = string<br/>    }))<br/>    tags = map(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_solo_project_user_settings"></a> [solo\_project\_user\_settings](#input\_solo\_project\_user\_settings) | Specific settings for solo project users | <pre>object({<br/>    max_role_assignments      = optional(number, 10)<br/>    allowed_resource_types    = optional(list(string), ["*"])<br/>    require_approval_for_prod = optional(bool, false) # More autonomy for solo projects<br/>    default_access_duration   = optional(string, "24h")<br/>    can_create_resources      = optional(bool, true)<br/>    resource_spending_limit   = optional(number, 1000) # USD per month<br/>  })</pre> | `{}` | no |
| <a name="input_state_backend_config"></a> [state\_backend\_config](#input\_state\_backend\_config) | Backend configuration for Terraform state management | <pre>object({<br/>    resource_group_name  = string<br/>    storage_account_name = string<br/>    container_name       = string<br/>    key_prefix           = string<br/>  })</pre> | `null` | no |
| <a name="input_subscription_isolation"></a> [subscription\_isolation](#input\_subscription\_isolation) | Enable separate state files for each subscription/environment combination | `bool` | `true` | no |
| <a name="input_technical_user_settings"></a> [technical\_user\_settings](#input\_technical\_user\_settings) | Specific settings for technical users | <pre>object({<br/>    max_role_assignments      = optional(number, 15)<br/>    allowed_resource_types    = optional(list(string), ["*"]) # All resource types<br/>    require_approval_for_prod = optional(bool, true)<br/>    default_access_duration   = optional(string, "24h")<br/>    can_create_resources      = optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id) | Specific tenant ID to create tenant-level assignments (optional, defaults to current tenant) | `string` | `null` | no |
| <a name="input_test_users"></a> [test\_users](#input\_test\_users) | Test user accounts for RBAC validation (for testing only) | <pre>map(object({<br/>    object_id      = string<br/>    user_type      = string<br/>    environment    = string<br/>    test_scenarios = list(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_environment_groups"></a> [environment\_groups](#output\_environment\_groups) | Environment groups information |
| <a name="output_group_hierarchy"></a> [group\_hierarchy](#output\_group\_hierarchy) | Complete group hierarchy structure |
| <a name="output_group_membership_commands"></a> [group\_membership\_commands](#output\_group\_membership\_commands) | PowerShell commands to add users to groups |
| <a name="output_group_object_ids"></a> [group\_object\_ids](#output\_group\_object\_ids) | All group object IDs for use in other modules |
| <a name="output_management_group_role_assignments"></a> [management\_group\_role\_assignments](#output\_management\_group\_role\_assignments) | Management group-level role assignments summary |
| <a name="output_organization_group"></a> [organization\_group](#output\_organization\_group) | Organization root group information |
| <a name="output_privileged_groups"></a> [privileged\_groups](#output\_privileged\_groups) | Groups with privileged access that require additional monitoring |
| <a name="output_project_groups"></a> [project\_groups](#output\_project\_groups) | Project-specific groups information |
| <a name="output_rbac_audit_info"></a> [rbac\_audit\_info](#output\_rbac\_audit\_info) | Information for RBAC auditing and compliance |
| <a name="output_rbac_summary_by_environment"></a> [rbac\_summary\_by\_environment](#output\_rbac\_summary\_by\_environment) | RBAC configuration summary organized by environment |
| <a name="output_rbac_summary_by_user_type"></a> [rbac\_summary\_by\_user\_type](#output\_rbac\_summary\_by\_user\_type) | RBAC configuration summary organized by user type |
| <a name="output_resource_group_role_assignments"></a> [resource\_group\_role\_assignments](#output\_resource\_group\_role\_assignments) | Resource group-level role assignments summary |
| <a name="output_role_assignment_validation"></a> [role\_assignment\_validation](#output\_role\_assignment\_validation) | Commands to validate role assignments |
| <a name="output_service_principal_credentials"></a> [service\_principal\_credentials](#output\_service\_principal\_credentials) | Service principal credentials (keep secure!) |
| <a name="output_service_principal_role_assignments"></a> [service\_principal\_role\_assignments](#output\_service\_principal\_role\_assignments) | Service principal role assignments summary |
| <a name="output_service_principals"></a> [service\_principals](#output\_service\_principals) | Service principal information |
| <a name="output_subscription_role_assignments"></a> [subscription\_role\_assignments](#output\_subscription\_role\_assignments) | Subscription-level role assignments summary |
| <a name="output_tenant_role_assignments"></a> [tenant\_role\_assignments](#output\_tenant\_role\_assignments) | Tenant-level role assignments summary |
| <a name="output_user_type_groups"></a> [user\_type\_groups](#output\_user\_type\_groups) | User type groups information (non-technical, technical, solo-project, admin) |
<!-- END_TF_DOCS -->

---

## Part of the AIRCLOUD Azure module catalog

Browse all modules with usage snippets in the [module catalog](https://aircloud-pl.github.io/) or on [github.com/AIRCLOUD-PL](https://github.com/AIRCLOUD-PL). Built and maintained by [AIRCLOUD](https://aircloud.com.pl): DevOps, cloud and AI engineering. Need a hand with Azure landing zones or platform engineering? See [aircloud.com.pl/consulting](https://aircloud.com.pl/consulting).
