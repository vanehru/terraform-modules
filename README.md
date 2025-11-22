# Terraform Modules Collection

Collection of reusable Terraform modules and infrastructure projects.

## 📁 Projects

### rpg-aiapp-infra
**Production-ready RPG Gaming Application Infrastructure**

Complete Azure infrastructure for a gaming application with full private endpoint security.

**Features:**
- 🔒 **Full Private Endpoint Architecture** - All backend services isolated from internet
- 💰 **Cost-Optimized** - ~$30-60/month using Cloud Shell for deployment
- ⚡ **Quick Deploy** - 15-minute setup from zero to production
- 🛡️ **Enterprise Security** - Zero-trust network with microsegmentation
- 🎮 **AI-Powered** - Integrated Azure OpenAI for game features

**Components:**
- Static Web App (Frontend)
- Azure Functions (Backend API)
- Azure SQL Database
- Azure Key Vault
- Azure OpenAI
- Storage Account with Private Endpoints
- VNet with 6 dedicated subnets
- Cloud Shell Container for secure deployment

**Cost Comparison:**
```
Traditional Bastion Approach: ~$230+/month
This Solution: ~$30-60/month (85% cost reduction!)
```

**Quick Start:**
```bash
cd rpg-aiapp-infra
terraform init
terraform apply -auto-approve
```

**Documentation:**
- [README.md](rpg-aiapp-infra/README.md) - Architecture overview and detailed setup
- [ARCHITECTURE.md](rpg-aiapp-infra/ARCHITECTURE.md) - Technical deep-dive
- [DEPLOYMENT-QUICKSTART.md](rpg-aiapp-infra/DEPLOYMENT-QUICKSTART.md) - 15-minute deployment guide

---

### demo-01, demo-02, demo-03
Basic Terraform examples and demonstrations.

## 🚀 Getting Started

### Prerequisites
- Azure CLI 2.50+
- Terraform 1.5+
- Azure Subscription

### Installation
```bash
# Clone repository
git clone <your-repo-url>
cd terraform-modules

# Navigate to desired project
cd rpg-aiapp-infra

# Initialize and deploy
terraform init
terraform plan
terraform apply
```

## 📚 Module Structure

Each module follows Terraform best practices:
```
module-name/
├── main.tf          # Main resource definitions
├── variables.tf     # Input variables
├── outputs.tf       # Output values
├── providers.tf     # Provider configuration (if applicable)
└── README.md        # Module documentation
```

## 🛡️ Security Features

The `rpg-aiapp-infra` project demonstrates enterprise-grade security:

1. **Network Isolation**: All backend services use private endpoints
2. **Subnet Microsegmentation**: 6 dedicated subnets for different tiers
3. **Managed Identities**: Zero credentials in code
4. **Secret Management**: Azure Key Vault integration
5. **Zero Trust**: Network-level security with VNet integration

## 💡 Best Practices

1. **Modular Design**: Reusable modules for each component
2. **Infrastructure as Code**: Version-controlled infrastructure
3. **Cost Optimization**: Cloud Shell instead of expensive jump boxes
4. **Security First**: Private endpoints by default
5. **Documentation**: Comprehensive docs for each project

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📄 License

[Your License Here]

## 📞 Support

For questions and support, please refer to individual project READMEs.
```