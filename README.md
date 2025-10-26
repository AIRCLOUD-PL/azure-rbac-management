# Comprehensive Multi-Level RBAC System

This system implements a sophisticated Role-Based Access Control (RBAC) solution for Azure environments with support for:

- **Multi-level group hierarchy** with nested Azure AD groups
- **Environment separation** (dev, test, prod) with appropriate permissions
- **User type segregation** (non-technical, technical, solo-project, admin)
- **Project-based isolation** with dedicated resource access
- **Compliance-ready** with audit trails and security controls

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
  source = "./modules/rbac-management"
  
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
  source = "./modules/multi-tenant-config"
  
  environment    = "prod"
  project_name   = "platform"
  organization   = "yourorg"
}
```

3. **Deploy RBAC System**
```hcl
module "rbac" {
  source = "./modules/rbac-management"
  
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