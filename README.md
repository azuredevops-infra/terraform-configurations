# Azure AKS Infrastructure Terraform Module

This comprehensive Terraform module creates and manages a production-ready Azure Kubernetes Service (AKS) cluster along with all necessary supporting infrastructure, security components, observability stack, and operational tools.

## 🚀 Features

### Core Infrastructure
- **AKS Cluster** with private endpoint support and Azure AD integration
- **Virtual Network** with optimized subnet configurations and NSGs
- **Azure Container Registry (ACR)** with geo-replication support
- **Azure Key Vault** for secrets and certificate management
- **Azure Storage Account** with lifecycle policies and private endpoints
- **Azure Service Bus** for messaging capabilities

### Security & Networking
- **Azure Firewall** with comprehensive rule sets for AKS traffic
- **Application Gateway** with Web Application Firewall (WAF)
- **Network Security Groups** with custom rules
- **Private Endpoints** for all PaaS services
- **Azure Bastion** for secure VM access
- **NAT Gateway** for controlled outbound traffic

### Observability & Monitoring
- **Azure Monitor** with Log Analytics and Application Insights
- **Open Source Observability Stack**:
  - **Grafana** for visualization and dashboards
  - **Prometheus** for metrics collection and alerting
  - **Loki** for log aggregation
  - **Tempo** for distributed tracing
  - **Mimir** for long-term metrics storage
  - **Promtail** for log collection
  - **OpenTelemetry Collector** for telemetry data

### Kubernetes Tools & Add-ons
- **NGINX Ingress Controller** with internal load balancer
- **Cert-Manager** for SSL certificate automation
- **External DNS** for automatic DNS management
- **Cluster Autoscaler** for node scaling
- **KEDA** for event-driven autoscaling
- **Velero** for backup and disaster recovery
- **ArgoCD** for GitOps deployments
- **Azure Key Vault CSI Driver** for secret injection

### Advanced Features
- **Workload Identity** for secure pod authentication
- **Multiple Node Pools** with custom configurations
- **GPU Support** for ML/AI workloads
- **Custom Storage Classes** for different storage needs
- **RBAC Configuration** for fine-grained access control
- **Certificate Management** with DNS integration
- **Lifecycle Management** for automated operations

## 📋 Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | >= 4.20.0 |
| azuread | >= 3.0.0 |
| kubernetes | >= 2.10.0 |
| helm | >= 2.5.0 |
| random | ~> 3.5.1 |

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Azure Resource Group                        │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌──────────────────┐  ┌─────────────────┐ │
│  │   Virtual       │  │  Application     │  │   Azure         │ │
│  │   Network       │  │  Gateway + WAF   │  │   Firewall      │ │
│  │                 │  │                  │  │                 │ │
│  │ ┌─────────────┐ │  │ ┌──────────────┐ │  │ ┌─────────────┐ │ │
│  │ │ AKS Subnet  │ │  │ │    Public    │ │  │ │   Firewall  │ │ │
│  │ └─────────────┘ │  │ │   Endpoint   │ │  │ │   Subnet    │ │ │
│  │ ┌─────────────┐ │  │ └──────────────┘ │  │ └─────────────┘ │ │
│  │ │   Private   │ │  └──────────────────┘  └─────────────────┘ │
│  │ │   Subnet    │ │                                            │
│  │ └─────────────┘ │  ┌──────────────────┐  ┌─────────────────┐ │
│  └─────────────────┘  │      Azure       │  │    Azure        │ │
│                       │    Key Vault     │  │   Bastion       │ │
│  ┌─────────────────┐  │                  │  │                 │ │
│  │      AKS        │  │ ┌──────────────┐ │  └─────────────────┘ │
│  │    Cluster      │  │ │ Certificates │ │                      │
│  │                 │  │ │   & Secrets  │ │  ┌─────────────────┐ │
│  │ ┌─────────────┐ │  │ └──────────────┘ │  │     Azure       │ │
│  │ │   System    │ │  └──────────────────┘  │   Service Bus   │ │
│  │ │ Node Pool   │ │                        │                 │ │
│  │ └─────────────┘ │  ┌──────────────────┐  └─────────────────┘ │
│  │ ┌─────────────┐ │  │      Azure       │                      │
│  │ │    User     │ │  │  Container Reg   │  ┌─────────────────┐ │
│  │ │ Node Pool   │ │  │                  │  │     Azure       │ │
│  │ └─────────────┘ │  └──────────────────┘  │    Storage      │ │
│  └─────────────────┘                        │                 │ │
│                       ┌──────────────────┐  │ ┌─────────────┐ │ │
│  ┌─────────────────┐  │   Log Analytics  │  │ │    Blob     │ │ │
│  │   Observability │  │    Workspace     │  │ │   Storage   │ │ │
│  │     Stack       │  │                  │  │ └─────────────┘ │ │
│  │                 │  │ ┌──────────────┐ │  │ ┌─────────────┐ │ │
│  │ ┌─────────────┐ │  │ │ Application  │ │  │ │    File     │ │ │
│  │ │   Grafana   │ │  │ │   Insights   │ │  │ │   Shares    │ │ │
│  │ └─────────────┘ │  │ └──────────────┘ │  │ └─────────────┘ │ │
│  │ ┌─────────────┐ │  └──────────────────┘  └─────────────────┘ │
│  │ │ Prometheus  │ │                                            │
│  │ └─────────────┘ │                                            │
│  │ ┌─────────────┐ │                                            │
│  │ │    Loki     │ │                                            │
│  │ └─────────────┘ │                                            │
│  │ ┌─────────────┐ │                                            │
│  │ │   Tempo     │ │                                            │
│  │ └─────────────┘ │                                            │
│  └─────────────────┘                                            │
└─────────────────────────────────────────────────────────────────┘
```

## 📁 Module Structure

```
.
├── main.tf                           # Main Terraform configuration
├── variables.tf                      # Input variables
├── outputs.tf                        # Output values
├── versions.tf                       # Provider versions and backend
├── README.md                         # This file
└── modules/
    ├── acr/                         # Azure Container Registry
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── aks/                         # Azure Kubernetes Service
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── rbac.tf
    ├── app-gateway/                 # Application Gateway + WAF
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── bastion/                     # Azure Bastion
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── firewall/                    # Azure Firewall
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── helm/                        # Helm Charts Management
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── keyvault/                    # Azure Key Vault
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── monitoring/                  # Azure Monitor & Alerts
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── network/                     # Virtual Network & Subnets
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── observability/               # Observability Stack
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── servicebus/                  # Azure Service Bus
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── storage/                     # Azure Storage Account
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## 🛠️ Usage

### Prerequisites

1. **Azure Account** with sufficient permissions to create:
   - Resource Groups
   - AKS Clusters
   - Virtual Networks
   - Storage Accounts
   - Key Vaults
   - Container Registries
   - Application Gateways
   - Firewalls

2. **Tools Required**:
   - Terraform >= 1.5.0
   - Azure CLI
   - kubectl
   - helm

3. **SSH Key Pair** for VM access

### Quick Start

1. **Clone the repository**:
```bash
git clone <repository-url>
cd azure-aks-terraform
```

2. **Configure Backend** (update `versions.tf`):
```hcl
terraform {
  backend "remote" {
    organization = "your-terraform-org"
    workspaces {
      name = "your-workspace-name"
    }
  }
}
```

3. **Create terraform.tfvars**:
```hcl
# Basic Configuration
prefix      = "mycompany"
environment = "dev"
location    = "East US"

# SSH Key for VM access
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAA..."

# Enable core components
enable_app_gateway    = true
enable_firewall      = true
enable_bastion       = false
enable_private_endpoints = true

# Enable observability
enable_opensource_grafana    = true
enable_opensource_prometheus = true
enable_observability_stack   = true

# Monitoring configuration
grafana_admin_password = "your-secure-password"
grafana_domain        = "your-domain.com"
alert_email          = "alerts@your-company.com"

tags = {
  Environment = "Development"
  Project     = "AKS-Infrastructure"
  Owner       = "Platform-Team"
}
```

4. **Initialize and Deploy**:
```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

5. **Configure kubectl**:
```bash
# Get AKS credentials
az aks get-credentials --resource-group <resource-group> --name <cluster-name>

# Verify connection
kubectl get nodes
```

### Advanced Configuration

#### Custom Node Pools
```hcl
node_pools = {
  "compute" = {
    vm_size             = "Standard_D4s_v3"
    node_count          = 3
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 10
    node_labels         = { "workload" = "compute" }
    node_taints         = []
    os_disk_size_gb     = 100
    os_type             = "Linux"
    priority            = "Regular"
    eviction_policy     = null
  }
  "gpu" = {
    vm_size             = "Standard_NC6s_v3"
    node_count          = 1
    enable_auto_scaling = true
    min_count           = 0
    max_count           = 5
    node_labels         = { "workload" = "gpu" }
    node_taints         = ["nvidia.com/gpu=true:NoSchedule"]
    os_disk_size_gb     = 100
    os_type             = "Linux"
    priority            = "Regular"
    eviction_policy     = null
  }
}
```

#### Workload Identity Configuration
```hcl
workload_identities = {
  "velero" = {
    role_assignments = [
      {
        scope      = "/subscriptions/your-subscription-id"
        scope_type = "subscription"
        role       = "Contributor"
      }
    ]
    federated_credentials = [
      {
        name     = "velero-federated-identity"
        subject  = "system:serviceaccount:velero:velero-server"
        audience = "api://AzureADTokenExchange"
      }
    ]
  }
}
```

#### Custom Helm Deployments
```hcl
helm_releases = {
  "argocd" = {
    repository       = "https://argoproj.github.io/argo-helm"
    chart            = "argo-cd"
    version          = "5.51.4"
    namespace        = "argocd"
    create_namespace = true
    values_file      = "helm-values/argocd-values.yaml"
    sets = {
      "server.service.type" = "ClusterIP"
    }
  }
}
```

## 🔧 Configuration Options

### Core Variables

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|:--------:|
| `prefix` | Resource prefix | `string` | `"aks"` | yes |
| `environment` | Environment name | `string` | `"dev"` | yes |
| `location` | Azure region | `string` | `"East US"` | yes |
| `ssh_public_key` | SSH public key | `string` | n/a | yes |

### Network Configuration

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `address_space` | VNet address space | `list(string)` | `["10.0.0.0/16"]` |
| `subnet_prefixes` | Subnet configurations | `map(string)` | See defaults |
| `enable_nat_gateway` | Enable NAT Gateway | `bool` | `false` |
| `enable_firewall` | Enable Azure Firewall | `bool` | `true` |

### AKS Configuration

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `kubernetes_version` | Kubernetes version | `string` | `"1.28.3"` |
| `node_count` | Initial node count | `number` | `2` |
| `vm_size` | Node VM size | `string` | `"Standard_D2s_v3"` |
| `enable_auto_scaling` | Enable autoscaling | `bool` | `true` |
| `private_cluster_enabled` | Private cluster | `bool` | `true` |

### Security Configuration

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `enable_private_endpoints` | Enable private endpoints | `bool` | `true` |
| `enable_app_gateway` | Enable Application Gateway | `bool` | `true` |
| `enable_waf` | Enable WAF | `bool` | `true` |
| `enable_bastion` | Enable Azure Bastion | `bool` | `false` |

### Observability Configuration

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `enable_opensource_grafana` | Enable Grafana | `bool` | `false` |
| `enable_opensource_prometheus` | Enable Prometheus | `bool` | `false` |
| `enable_observability_stack` | Enable full stack | `bool` | `false` |
| `grafana_admin_password` | Grafana password | `string` | n/a |

## 📊 Outputs

### Infrastructure Outputs
- `resource_group_name` - Resource group name
- `kubernetes_cluster_name` - AKS cluster name
- `oidc_issuer_url` - OIDC issuer URL

### Access Information
- `application_urls` - Application access URLs
- `access_credentials` - Access credentials (sensitive)
- `cluster_access_info` - kubectl configuration commands

### Service Endpoints
- `azure_services` - Azure service endpoints
- `network_config` - Network configuration details
- `monitoring_config` - Monitoring stack information

## 🔐 Security Best Practices

### Network Security
- All PaaS services use private endpoints
- Network Security Groups with minimal required rules
- Azure Firewall for egress traffic control
- Private AKS cluster by default

### Identity & Access
- Azure AD integration for cluster access
- Workload Identity for pod authentication
- RBAC configuration for fine-grained permissions
- Key Vault for secrets management

### Certificate Management
- Automated SSL certificate management with cert-manager
- Key Vault integration for certificate storage
- DNS automation with external-dns

## 📈 Monitoring & Observability

### Metrics & Alerting
- **Prometheus** for metrics collection
- **Grafana** for visualization
- **Azure Monitor** for platform metrics
- **Application Insights** for application telemetry

### Logging
- **Loki** for log aggregation
- **Promtail** for log collection
- **Azure Log Analytics** for platform logs

### Tracing
- **Tempo** for distributed tracing
- **OpenTelemetry** for telemetry collection

### Long-term Storage
- **Mimir** for long-term metrics storage
- **Azure Storage** for log archive

## 🛡️ Backup & Disaster Recovery

### Backup Strategy
- **Velero** for Kubernetes backup
- **Azure Storage** lifecycle policies
- **Geo-replication** for ACR

### High Availability
- **Multiple availability zones**
- **Auto-scaling** configurations
- **Health checks** and monitoring

## 🚦 Deployment Strategies

### Environment Promotion
```bash
# Development
terraform workspace select dev
terraform apply -var-file="environments/dev.tfvars"

# Staging
terraform workspace select staging
terraform apply -var-file="environments/staging.tfvars"

# Production
terraform workspace select prod
terraform apply -var-file="environments/prod.tfvars"
```

### Blue-Green Deployments
Use ArgoCD for GitOps-based deployments with the provided configuration.

## 🔧 Maintenance

### Regular Tasks
- Monitor cluster health via Grafana dashboards
- Review security alerts in Azure Security Center
- Update Kubernetes versions quarterly
- Review and rotate certificates annually

### Scaling Operations
```bash
# Scale node pools
az aks nodepool scale --resource-group <rg> --cluster-name <cluster> --name <nodepool> --node-count <count>

# Update cluster version
az aks upgrade --resource-group <rg> --name <cluster> --kubernetes-version <version>
```

## 🐛 Troubleshooting

### Common Issues

1. **Private Cluster Access**:
   ```bash
   # Use Bastion or management VM
   az aks command invoke --resource-group <rg> --name <cluster> --command "kubectl get nodes"
   ```

2. **Certificate Issues**:
   ```bash
   # Check cert-manager logs
   kubectl logs -n cert-manager deployment/cert-manager
   ```

3. **Ingress Problems**:
   ```bash
   # Check NGINX ingress logs
   kubectl logs -n ingress-nginx deployment/nginx-ingress-controller
   ```

### Debug Commands
```bash
# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Check ingress
kubectl get ingress --all-namespaces

# Check certificates
kubectl get certificates --all-namespaces
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

### Development Setup
```bash
# Install pre-commit hooks
pre-commit install

# Run tests
terraform fmt -check
terraform validate
tflint
```

## 📚 Additional Resources

- [Azure AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Charts](https://helm.sh/docs/)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Note**: This module is designed for production use but always review and test configurations in a development environment first.
