# General
variable "prefix" {
  description = "The prefix for all resources"
  type        = string
  default     = "aks"
}

variable "environment" {
  description = "The environment (dev, test, prod, etc.)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "The Azure location where resources will be created"
  type        = string
  default     = "East US"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    Environment = "Development"
    ManagedBy   = "Terraform"
    Project     = "AKS-Infrastructure"
  }
}

# Network
variable "address_space" {
  description = "The address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_prefixes" {
  description = "The address prefixes for the subnets"
  type        = map(string)
  default = {
    aks     = "10.0.1.0/24"
    private = "10.0.2.0/24"
  }
}

variable "firewall_subnet_cidr" {
  description = "The CIDR for the Azure Firewall subnet"
  type        = string
  default     = "10.0.3.0/26" # Must be at least /26
}

variable "app_gateway_subnet_cidr" {
  description = "The CIDR for the Application Gateway subnet"
  type        = string
  default     = "10.0.4.0/24"
}

variable "app_gateway_private_ip" {
  description = "The private IP address for the Application Gateway"
  type        = string
  default     = "10.0.4.100"
}

# AKS
variable "kubernetes_version" {
  description = "The Kubernetes version"
  type        = string
  default     = "1.28.3"
}

variable "node_count" {
  description = "The initial number of nodes in the node pool"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "The size of the Virtual Machine"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "admin_username" {
  description = "The admin username for the Linux VMs"
  type        = string
  default     = "azureadmin"
}

variable "ssh_public_key" {
  description = "The SSH public key for the Linux VMs"
  type        = string
}

variable "enable_auto_scaling" {
  description = "Enable auto scaling for the AKS cluster"
  type        = bool
  default     = true
}

variable "min_count" {
  description = "The minimum number of nodes for auto-scaling"
  type        = number
  default     = 1
}

variable "max_count" {
  description = "The maximum number of nodes for auto-scaling"
  type        = number
  default     = 5
}

variable "private_cluster_enabled" {
  description = "Enable private cluster for AKS"
  type        = bool
  default     = true
}

variable "enable_node_pools" {
  description = "Enable additional node pools"
  type        = bool
  default     = true
}

variable "node_pools" {
  description = "Map of node pool configurations"
  type = map(object({
    vm_size             = string
    node_count          = number
    enable_auto_scaling = bool
    min_count           = number
    max_count           = number
    node_labels         = map(string)
    node_taints         = list(string)
    os_disk_size_gb     = number
    os_type             = string
    priority            = string
    eviction_policy     = string
  }))
  default = {
    "user" = {
      vm_size             = "Standard_D2s_v3"
      node_count          = 2
      enable_auto_scaling = true
      min_count           = 1
      max_count           = 5
      node_labels         = { "nodepool-type" = "user" }
      node_taints         = []
      os_disk_size_gb     = 50
      os_type             = "Linux"
      priority            = "Regular"
      eviction_policy     = null
    }
  }
}

variable "enable_gpu" {
  description = "Enable GPU node pool"
  type        = bool
  default     = false
}

variable "gpu_node_count" {
  description = "The number of GPU nodes"
  type        = number
  default     = 1
}

variable "gpu_min_count" {
  description = "The minimum number of GPU nodes for auto-scaling"
  type        = number
  default     = 0
}

variable "gpu_max_count" {
  description = "The maximum number of GPU nodes for auto-scaling"
  type        = number
  default     = 3
}

# ACR
variable "acr_sku" {
  description = "The SKU for the Azure Container Registry"
  type        = string
  default     = "Premium"
}

variable "acr_geo_replications" {
  description = "Locations for ACR geo-replication"
  type        = list(string)
  default     = []
}

# Key Vault
variable "key_vault_allowed_ips" {
  description = "List of allowed IP addresses for the Key Vault"
  type        = list(string)
  default     = []
}

# Service Bus
variable "service_bus_sku" {
  description = "The SKU of the Service Bus Namespace"
  type        = string
  default     = "Standard"
}

variable "service_bus_capacity" {
  description = "The capacity of the Service Bus Namespace"
  type        = number
  default     = 0
}

variable "service_bus_topics" {
  description = "Map of Service Bus topics and subscriptions"
  type        = map(list(string))
  default = {
    "events" = ["subscription1", "subscription2"]
  }
}

variable "service_bus_queues" {
  description = "List of Service Bus queue names"
  type        = list(string)
  default = ["queue1", "queue2"]
}

# Storage
variable "storage_account_tier" {
  description = "The tier for the storage account"
  type        = string
  default     = "Standard"
}

variable "storage_account_replication_type" {
  description = "The replication type for the storage account"
  type        = string
  default     = "LRS"
}

variable "storage_container_names" {
  description = "The names of the containers to create"
  type        = list(string)
  default     = ["data", "backups", "artifacts"]
}

variable "storage_file_share_names" {
  description = "The names of the file shares to create"
  type        = list(string)
  default     = ["config", "persistent"]
}

variable "storage_file_share_quota" {
  description = "The quota in GB for the file shares"
  type        = number
  default     = 50
}

variable "storage_allowed_ips" {
  description = "List of allowed IP addresses for the storage account"
  type        = list(string)
  default     = []
}

# Monitoring
variable "log_analytics_workspace_sku" {
  description = "The SKU for the Log Analytics Workspace"
  type        = string
  default     = "PerGB2018"
}

variable "log_retention_in_days" {
  description = "The retention period for logs in days"
  type        = number
  default     = 30
}

variable "alert_email" {
  description = "Email address for alerts"
  type        = string
  default     = "admin@example.com"
}

variable "enable_grafana" {
  description = "Enable Azure Managed Grafana"
  type        = bool
  default     = true
}

variable "enable_grafana_datasources" {
  description = "Enable automatic Grafana data source configuration"
  type        = bool
  default     = true
}

variable "grafana_admin_users" {
  description = "List of user object IDs to grant Grafana Admin access"
  type        = list(string)
  default     = []
}

variable "grafana_viewer_users" {
  description = "List of user object IDs to grant Grafana Viewer access"
  type        = list(string)
  default     = []
}

variable "enable_prometheus" {
  description = "Enable Azure Monitor managed Prometheus"
  type        = bool
  default     = true
}

variable "enable_defender" {
  description = "Enable Microsoft Defender for Cloud"
  type        = bool
  default     = true
}

# Network Security
variable "enable_firewall" {
  description = "Enable Azure Firewall"
  type        = bool
  default     = true
}

variable "enable_private_endpoints" {
  description = "Enable Private Endpoints for PaaS services"
  type        = bool
  default     = true
}

# Application Gateway
variable "enable_app_gateway" {
  description = "Enable Application Gateway as ingress"
  type        = bool
  default     = true
}

variable "enable_waf" {
  description = "Enable Web Application Firewall on Application Gateway"
  type        = bool
  default     = true
}

variable "waf_mode" {
  description = "WAF mode - Detection or Prevention"
  type        = string
  default     = "Prevention"
  validation {
    condition     = contains(["Detection", "Prevention"], var.waf_mode)
    error_message = "WAF mode must be either 'Detection' or 'Prevention'."
  }
}

variable "enable_firewall_route" {
  description = "Enable route to firewall"
  type        = bool
  default     = false
}

variable "firewall_private_ip" {
  description = "The private IP address of the Azure Firewall"
  type        = string
  default     = null
}

#Azure Bastion
variable "enable_bastion" {
  description = "Enable Azure Bastion"
  type        = bool
  default     = false
}

variable "bastion_subnet_cidr" {
  description = "The CIDR for the Azure Bastion subnet"
  type        = string
  default     = ""
}

variable "create_management_vm" {
  description = "Create a management VM accessible via Bastion"
  type        = bool
  default     = true
}

variable "management_subnet_cidr" {
  description = "The CIDR for the management subnet"
  type        = string
  default     = ""
}

# Helm Charts

variable "helm_releases" {
  description = "Map of Helm releases to deploy"
  type = map(object({
    repository       = string
    chart            = string
    version          = optional(string)
    namespace        = string
    create_namespace = optional(bool, true)
    sets             = optional(map(string), {})
    values_file      = optional(string, "")
    values_yaml      = optional(string, "")
    values           = optional(list(string), [])
  }))
  default = {}
}

variable "helm_template_values" {
  description = "Enable templating for helm values files"
  type        = bool
  default     = true
}

variable "helm_template_vars" {
  description = "Variables to pass to helm values templates"
  type        = map(any)
  default     = {}
}
variable "enable_helm_charts" {
  description = "Enable Helm chart deployments"
  type        = bool
  default     = true
}

variable "enable_nginx_ingress" {
  description = "Enable Nginx Ingress Controller"
  type        = bool
  default     = true
}

variable "enable_cert_manager" {
  description = "Enable cert-manager"
  type        = bool
  default     = true
}

variable "enable_external_dns" {
  description = "Enable external-dns"
  type        = bool
  default     = false
}

variable "enable_prometheus_stack" {
  description = "Enable Prometheus monitoring stack"
  type        = bool
  default     = false
}

variable "enable_argocd" {
  description = "Enable ArgoCD"
  type        = bool
  default     = false
}

variable "enable_cluster_autoscaler" {
  description = "Enable cluster autoscaler"
  type        = bool
  default     = false
}

variable "enable_keda" {
  description = "Enable KEDA"
  type        = bool
  default     = false
}

variable "enable_azure_key_vault_csi" {
  description = "Enable Azure Key Vault CSI driver"
  type        = bool
  default     = true
}

variable "external_dns_domain_filters" {
  description = "Domain filters for external-dns"
  type        = list(string)
  default     = []
}

variable "external_dns_client_id" {
  description = "Client ID for external-dns"
  type        = string
  default     = ""
}

variable "external_dns_client_secret" {
  description = "Client secret for external-dns"
  type        = string
  default     = ""
  sensitive   = true
}

variable "enable_velero" {
  description = "Enable Velero for backup (used for conditional logic)"
  type        = bool
  default     = false
}

variable "deploy_helm_charts" {
  description = "Deploy Helm charts (set to false for initial infrastructure deployment)"
  type        = bool
  default     = false
}

# Certificate Management
variable "certificates_config" {
  description = "Configuration for certificates in Key Vault"
  type = map(object({
    issuer             = optional(string, "Self")
    validity_months    = optional(number, 12)
    san_names          = optional(list(string), [])
    create_dns_record  = optional(bool, false)
    dns_record_name    = optional(string, "")
    dns_ttl            = optional(number, 300)
    dns_records        = optional(list(string), [])
  }))
  default = {}
}

variable "root_domain" {
  description = "Root domain for DNS zone"
  type        = string
  default     = ""
}

variable "create_dns_zone" {
  description = "Create new DNS zone or use existing"
  type        = bool
  default     = false
}

variable "dns_zone_resource_group" {
  description = "Resource group of existing DNS zone"
  type        = string
  default     = ""
}

# Workload Identities
variable "workload_identities" {
  description = "Workload identity configurations"
  type = map(object({
    role_assignments = list(object({
      scope      = string
      scope_type = string
      role       = string
    }))
    federated_credentials = optional(list(object({
      name     = string
      subject  = string
      audience = string
    })), [])
  }))
  default = {}
}

# Enhanced Storage Classes
variable "custom_storage_classes" {
  description = "Custom storage class configurations"
  type = map(object({
    provisioner            = string
    reclaim_policy        = optional(string, "Delete")
    volume_binding_mode   = optional(string, "Immediate")
    allow_volume_expansion = optional(bool, true)
    parameters            = optional(map(string), {})
    mount_options         = optional(list(string))
    annotations           = optional(map(string), {})
    labels               = optional(map(string), {})
  }))
  default = {}
}

# NAT Gateway
variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = false
}

variable "nat_gateway_count" {
  description = "Number of NAT Gateways"
  type        = number
  default     = 1
}

variable "nat_gateway_zones" {
  description = "Availability zones for NAT Gateway"
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "nat_gateway_idle_timeout" {
  description = "NAT Gateway idle timeout"
  type        = number
  default     = 10
}

variable "associate_nat_gateway_to_aks" {
  description = "Associate NAT Gateway to AKS subnet"
  type        = bool
  default     = true
}

# Custom Network Rules
variable "custom_network_rules" {
  description = "Custom network security rules"
  type = map(object({
    priority                     = number
    direction                    = string
    access                       = string
    protocol                     = string
    source_port_ranges          = optional(list(string), ["*"])
    destination_port_ranges     = optional(list(string), ["*"])
    source_address_prefixes     = optional(list(string), ["*"])
    destination_address_prefixes = optional(list(string), ["*"])
    description                  = optional(string, "")
  }))
  default = {}
}

# Kubernetes RBAC
variable "k8s_cluster_roles" {
  description = "Custom Kubernetes cluster roles"
  type = map(object({
    labels = optional(map(string), {})
    rules = list(object({
      api_groups = list(string)
      resources  = list(string)
      verbs      = list(string)
    }))
  }))
  default = {}
}

variable "k8s_roles" {
  description = "Custom Kubernetes roles"
  type = map(object({
    namespace = string
    labels    = optional(map(string), {})
    rules = list(object({
      api_groups = list(string)
      resources  = list(string)
      verbs      = list(string)
    }))
  }))
  default = {}
}

variable "k8s_cluster_role_bindings" {
  description = "Kubernetes cluster role bindings"
  type = map(object({
    role_name = string
    labels    = optional(map(string), {})
    subjects = list(object({
      kind      = string
      name      = string
      namespace = optional(string)
    }))
  }))
  default = {}
}

variable "k8s_role_bindings" {
  description = "Kubernetes role bindings"
  type = map(object({
    namespace = string
    role_kind = string
    role_name = string
    labels    = optional(map(string), {})
    subjects = list(object({
      kind      = string
      name      = string
      namespace = optional(string)
    }))
  }))
  default = {}
}

# Observability Stack Configuration
variable "enable_observability_stack" {
  description = "Enable comprehensive observability stack (Loki, Tempo, Mimir)"
  type        = bool
  default     = false
}

variable "observability_namespace" {
  description = "Namespace for observability stack"
  type        = string
  default     = "observability"
}

# Loki Configuration
variable "enable_loki" {
  description = "Enable Loki for log aggregation"
  type        = bool
  default     = true
}

variable "loki_retention_period" {
  description = "Log retention period for Loki"
  type        = string
  default     = "720h"  # 30 days
}

variable "loki_storage_size" {
  description = "Storage size for Loki"
  type        = string
  default     = "100Gi"
}

variable "loki_resources" {
  description = "Resource limits for Loki"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "500m"
      memory = "1Gi"
    }
    limits = {
      cpu    = "1000m"
      memory = "2Gi"
    }
  }
}

# Tempo Configuration
variable "enable_tempo" {
  description = "Enable Tempo for distributed tracing"
  type        = bool
  default     = true
}

variable "tempo_retention_period" {
  description = "Trace retention period for Tempo"
  type        = string
  default     = "168h"  # 7 days
}

variable "tempo_storage_size" {
  description = "Storage size for Tempo"
  type        = string
  default     = "50Gi"
}

variable "tempo_resources" {
  description = "Resource limits for Tempo"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "500m"
      memory = "1Gi"
    }
    limits = {
      cpu    = "1000m"
      memory = "2Gi"
    }
  }
}

# Mimir Configuration
variable "enable_mimir" {
  description = "Enable Mimir for long-term metrics storage"
  type        = bool
  default     = true
}

variable "mimir_retention_period" {
  description = "Metrics retention period for Mimir"
  type        = string
  default     = "8760h"  # 1 year
}

variable "mimir_storage_size" {
  description = "Storage size for Mimir"
  type        = string
  default     = "200Gi"
}

variable "mimir_resources" {
  description = "Resource limits for Mimir"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "1000m"
      memory = "2Gi"
    }
    limits = {
      cpu    = "2000m"
      memory = "4Gi"
    }
  }
}

# Additional Components
variable "enable_promtail" {
  description = "Enable Promtail for log collection"
  type        = bool
  default     = true
}

variable "enable_otel_collector" {
  description = "Enable OpenTelemetry Collector"
  type        = bool
  default     = true
}

variable "grafana_fqdn" {
  description = "Grafana FQDN for Application Gateway routing"
  type        = string
  default     = ""
}