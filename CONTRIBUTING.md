# Contributing to Azure Modules Validation

## 🤝 Welcome Contributors!

Thank you for your interest in contributing to our enterprise-grade Azure Terraform modules! This guide will help you get started.

## 📋 Prerequisites

- **Terraform**: >= 1.5.0
- **Go**: >= 1.22
- **Azure CLI**: Latest version
- **Git**: Latest version
- **Valid Azure subscription** with appropriate permissions

## 🏗️ Development Environment Setup

### 1. Clone the Repository
```bash
git clone https://github.com/AIRCLOUD-PL/azure-modules-validation.git
cd azure-modules-validation
```

### 2. Set Up Azure Credentials
```bash
# Method 1: Azure CLI
az login
az account set --subscription "your-subscription-id"

# Method 2: Environment Variables
export ARM_TENANT_ID="your-tenant-id"
export ARM_SUBSCRIPTION_ID="your-subscription-id" 
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
```

### 3. Test Environment
```bash
# Test a specific module
cd modules/azure-aks-module/test
go mod tidy
go test -v -timeout 30m
```

## 📝 Contribution Workflow

### 1. Create Feature Branch
```bash
git checkout -b feature/your-feature-name
```

### 2. Make Changes
- Follow our coding standards
- Add tests for new functionality
- Update documentation

### 3. Run Tests Locally
```bash
# Test specific module
cd modules/your-module/test
go test -v

# Validate Terraform
cd modules/your-module
terraform init -backend=false
terraform validate
```

### 4. Submit Pull Request
- Fill out PR template completely
- Ensure all checks pass
- Request review from appropriate team

## 🎯 Types of Contributions

### 🐛 Bug Fixes
- Fix security vulnerabilities
- Resolve Terraform validation issues
- Improve test reliability

### ✨ New Features
- Add new Azure modules
- Enhance existing modules
- Improve security compliance

### 📚 Documentation
- Update README files
- Improve code comments
- Add usage examples

### 🧪 Testing
- Add test coverage
- Improve test reliability
- Add security tests

## 📐 Coding Standards

### Terraform Code
```hcl
# Use descriptive resource names
resource "azurerm_storage_account" "main" {
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
  location            = var.location
  
  # Always include security configurations
  https_traffic_only_enabled = true
  min_tls_version            = "TLS1_2"
  
  tags = merge(local.default_tags, var.tags)
}
```

### Go Test Code
```go
func TestAzureModule(t *testing.T) {
    t.Parallel()
    
    // Setup test configuration
    config := TestConfig{
        TenantID:       os.Getenv("ARM_TENANT_ID"),
        SubscriptionID: os.Getenv("ARM_SUBSCRIPTION_ID"),
        // ... other config
    }
    
    // Skip if credentials not available
    if config.TenantID == "" {
        t.Skip("Skipping test - Azure credentials not configured")
    }
    
    // Test implementation
    // ...
}
```

## 🔒 Security Guidelines

### Security Requirements
- ✅ All PaaS services must use private endpoints
- ✅ Enable encryption at rest and in transit
- ✅ Implement RBAC and least privilege access
- ✅ Add diagnostic settings and monitoring
- ✅ Follow Azure Security Benchmark

### Security Testing
- All modules must pass security compliance tests
- Regular vulnerability scanning required
- Security audit before major releases

## 📊 Module Structure

Each module must follow this structure:
```
modules/azure-example-module/
├── main.tf              # Main resources
├── variables.tf         # Input variables
├── outputs.tf          # Output values
├── versions.tf         # Provider versions
├── policies.tf         # Azure policies
├── README.md           # Module documentation
├── SECURITY.md         # Security considerations
├── examples/           
│   └── basic/          # Usage examples
├── test/              
│   ├── go.mod         # Go module definition
│   └── *_test.go      # Terratest files
└── .github/workflows/ # CI/CD pipeline
```

## 🧪 Testing Requirements

### Unit Tests
- Test all module functionality
- Validate security configurations
- Check compliance requirements

### Integration Tests
- Multi-environment testing
- Cross-module compatibility
- End-to-end scenarios

### Security Tests
- RBAC validation
- Network security verification
- Encryption compliance

## 📋 Pull Request Checklist

Before submitting your PR, ensure:

- [ ] **Code Quality**
  - [ ] Terraform code validates successfully
  - [ ] Go code builds without errors
  - [ ] All tests pass locally
  - [ ] Code follows style guidelines

- [ ] **Documentation**
  - [ ] README updated (if applicable)
  - [ ] Code comments added
  - [ ] Examples provided
  - [ ] CHANGELOG updated

- [ ] **Security**
  - [ ] Security review completed
  - [ ] No secrets in code
  - [ ] Compliance requirements met
  - [ ] Security tests added

- [ ] **Testing**
  - [ ] New tests for new functionality
  - [ ] Existing tests still pass
  - [ ] Test coverage maintained
  - [ ] Integration tests updated

## 🎖️ Recognition

Contributors will be recognized in:
- Release notes
- Repository contributors section  
- Annual contributor appreciation
- Technical blog posts (with permission)

## 📞 Getting Help

### Communication Channels
- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and ideas
- **Slack**: `#azure-modules` channel (internal)
- **Email**: azure-modules@aircloud.pl

### Code Review Process
1. **Automated Checks**: CI/CD pipeline runs automatically
2. **Peer Review**: At least 2 approvals required
3. **Security Review**: Security team review for sensitive changes
4. **Maintainer Approval**: Final approval from module maintainers

## 🏆 Contributor Levels

### 🌟 Contributor
- Submit PRs and issues
- Participate in discussions
- Help with documentation

### 🚀 Regular Contributor  
- Consistent contributions
- Help review other PRs
- Mentor new contributors

### 👑 Maintainer
- Module ownership
- Release management
- Strategic planning

## 📜 Code of Conduct

We follow the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). Please read and follow these guidelines to ensure a welcoming environment for all contributors.

## 📄 License

By contributing, you agree that your contributions will be licensed under the same license as this project.

---

**Happy Contributing!** 🎉

For questions or assistance, don't hesitate to reach out to our maintainers or open an issue.