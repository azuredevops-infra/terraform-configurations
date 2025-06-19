# General variables
variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "node_resource_group" {
  description = "Name of the node resource group"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "cluster_dependency" {
  description = "Dependency to ensure cluster is ready"
  type        = any
  default     = null
}

# Nginx Ingress Controller
variable "enable_nginx_ingress" {
  description = "Enable Nginx Ingress Controller"
  type        = bool
  default     = true
}

variable "ingress_namespace" {
  description = "Namespace for ingress controller"
  type        = string
  default     = "ingress-nginx"
}

variable "nginx_ingress_version" {
  description = "Version of nginx ingress chart"
  type        = string
  default     = "4.8.3"
}

variable "nginx_ingress_replica_count" {
  description = "Number of nginx ingress replicas"
  type        = number
  default     = 2
}

variable "nginx_ingress_service_type" {
  description = "Service type for nginx ingress"
  type        = string
  default     = "LoadBalancer"
}

variable "nginx_ingress_service_annotations" {
  description = "Service annotations for nginx ingress"
  type        = map(string)
  default     = {}
}

variable "nginx_ingress_resources" {
  description = "Resources for nginx ingress controller"
  type        = map(any)
  default = {
    requests = {
      cpu    = "100m"
      memory = "90Mi"
    }
    limits = {
      cpu    = "500m"
      memory = "256Mi"
    }
  }
}

variable "nginx_ingress_node_selector" {
  description = "Node selector for nginx ingress"
  type        = map(string)
  default     = {}
}

variable "nginx_ingress_tolerations" {
  description = "Tolerations for nginx ingress"
  type        = list(any)
  default     = []
}

variable "nginx_ingress_default_backend_enabled" {
  description = "Enable default backend for nginx ingress"
  type        = bool
  default     = true
}

# Cert Manager
variable "enable_cert_manager" {
  description = "Enable cert-manager"
  type        = bool
  default     = true
}

variable "cert_manager_namespace" {
  description = "Namespace for cert-manager"
  type        = string
  default     = "cert-manager"
}

variable "cert_manager_version" {
  description = "Version of cert-manager chart"
  type        = string
  default     = "v1.13.2"
}

variable "cert_manager_resources" {
  description = "Resources for cert-manager"
  type        = map(any)
  default = {
    requests = {
      cpu    = "10m"
      memory = "32Mi"
    }
    limits = {
      cpu    = "100m"
      memory = "128Mi"
    }
  }
}

variable "cert_manager_node_selector" {
  description = "Node selector for cert-manager"
  type        = map(string)
  default     = {}
}

variable "cert_manager_tolerations" {
  description = "Tolerations for cert-manager"
  type        = list(any)
  default     = []
}

# External DNS
variable "enable_external_dns" {
  description = "Enable external-dns"
  type        = bool
  default     = false
}

variable "external_dns_namespace" {
  description = "Namespace for external-dns"
  type        = string
  default     = "external-dns"
}

variable "external_dns_version" {
  description = "Version of external-dns chart"
  type        = string
  default     = "1.13.1"
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

variable "external_dns_domain_filters" {
  description = "Domain filters for external-dns"
  type        = list(string)
  default     = []
}

variable "external_dns_resources" {
  description = "Resources for external-dns"
  type        = map(any)
  default = {
    requests = {
      cpu    = "10m"
      memory = "32Mi"
    }
    limits = {
      cpu    = "50m"
      memory = "64Mi"
    }
  }
}

variable "external_dns_node_selector" {
  description = "Node selector for external-dns"
  type        = map(string)
  default     = {}
}

variable "external_dns_tolerations" {
  description = "Tolerations for external-dns"
  type        = list(any)
  default     = []
}

# Prometheus Stack
variable "enable_prometheus_stack" {
  description = "Enable Prometheus monitoring stack"
  type        = bool
  default     = false
}

variable "monitoring_namespace" {
  description = "Namespace for monitoring components"
  type        = string
  default     = "monitoring"
}

variable "prometheus_stack_version" {
  description = "Version of kube-prometheus-stack chart"
  type        = string
  default     = "54.0.1"
}

variable "prometheus_grafana_enabled" {
  description = "Enable Grafana in prometheus stack"
  type        = bool
  default     = true
}

variable "prometheus_grafana_service_type" {
  description = "Service type for Grafana"
  type        = string
  default     = "ClusterIP"
}

variable "prometheus_grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  default     = "admin123"
  sensitive   = true
}

variable "prometheus_grafana_persistence_enabled" {
  description = "Enable persistence for Grafana"
  type        = bool
  default     = true
}

variable "prometheus_grafana_persistence_size" {
  description = "Storage size for Grafana persistence"
  type        = string
  default     = "10Gi"
}

variable "prometheus_grafana_resources" {
  description = "Resources for Grafana"
  type        = map(any)
  default = {
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
  }
}

variable "prometheus_retention" {
  description = "Retention period for Prometheus"
  type        = string
  default     = "30d"
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus"
  type        = string
  default     = "50Gi"
}

variable "prometheus_resources" {
  description = "Resources for Prometheus"
  type        = map(any)
  default = {
    requests = {
      cpu    = "200m"
      memory = "400Mi"
    }
    limits = {
      cpu    = "1000m"
      memory = "2Gi"
    }
  }
}

variable "prometheus_alertmanager_enabled" {
  description = "Enable Alertmanager"
  type        = bool
  default     = true
}

variable "prometheus_alertmanager_resources" {
  description = "Resources for Alertmanager"
  type        = map(any)
  default = {
    requests = {
      cpu    = "10m"
      memory = "32Mi"
    }
    limits = {
      cpu    = "100m"
      memory = "128Mi"
    }
  }
}

# ArgoCD
variable "enable_argocd" {
  description = "Enable ArgoCD"
  type        = bool
  default     = false
}

variable "argocd_namespace" {
  description = "Namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "argocd_version" {
  description = "Version of ArgoCD chart"
  type        = string
  default     = "5.51.4"
}

variable "argocd_image_tag" {
  description = "Image tag for ArgoCD"
  type        = string
  default     = "v2.9.2"
}

variable "argocd_server_service_type" {
  description = "Service type for ArgoCD server"
  type        = string
  default     = "ClusterIP"
}

variable "argocd_server_ingress_enabled" {
  description = "Enable ingress for ArgoCD server"
  type        = bool
  default     = false
}

variable "argocd_server_ingress_annotations" {
  description = "Ingress annotations for ArgoCD server"
  type        = map(string)
  default     = {}
}

variable "argocd_server_ingress_hosts" {
  description = "Ingress hosts for ArgoCD server"
  type        = list(string)
  default     = []
}

variable "argocd_server_ingress_tls" {
  description = "Ingress TLS for ArgoCD server"
  type        = list(any)
  default     = []
}

variable "argocd_server_resources" {
  description = "Resources for ArgoCD server"
  type        = map(any)
  default = {
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
  }
}

variable "argocd_controller_resources" {
  description = "Resources for ArgoCD controller"
  type        = map(any)
  default = {
    requests = {
      cpu    = "250m"
      memory = "256Mi"
    }
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
  }
}

variable "argocd_repo_server_resources" {
  description = "Resources for ArgoCD repo server"
  type        = map(any)
  default = {
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
  }
}

variable "argocd_dex_enabled" {
  description = "Enable Dex for ArgoCD"
  type        = bool
  default     = false
}

# Velero
variable "enable_velero" {
  description = "Enable Velero for backup"
  type        = bool
  default     = false
}

variable "velero_namespace" {
  description = "Namespace for Velero"
  type        = string
  default     = "velero"
}

variable "velero_version" {
  description = "Version of Velero chart"
  type        = string
  default     = "5.1.4"
}

variable "velero_storage_account" {
  description = "Storage account for Velero backups"
  type        = string
  default     = ""
}

variable "velero_storage_container" {
  description = "Storage container for Velero backups"
  type        = string
  default     = "velero"
}

variable "velero_client_id" {
  description = "Client ID for Velero"
  type        = string
  default     = ""
}

variable "velero_schedules" {
  description = "Backup schedules for Velero"
  type        = map(any)
  default = {
    daily = {
      schedule = "0 2 * * *"
      template = {
        ttl = "720h"
      }
    }
  }
}

variable "velero_resources" {
  description = "Resources for Velero"
  type        = map(any)
  default = {
    requests = {
      cpu    = "500m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "1000m"
      memory = "512Mi"
    }
  }
}

# Cluster Autoscaler
variable "enable_cluster_autoscaler" {
  description = "Enable cluster autoscaler"
  type        = bool
  default     = false
}

variable "cluster_autoscaler_namespace" {
  description = "Namespace for cluster autoscaler"
  type        = string
  default     = "kube-system"
}

variable "cluster_autoscaler_version" {
  description = "Version of cluster autoscaler chart"
  type        = string
  default     = "9.29.0"
}

variable "cluster_autoscaler_client_id" {
  description = "Client ID for cluster autoscaler"
  type        = string
  default     = ""
}

variable "cluster_autoscaler_resources" {
  description = "Resources for cluster autoscaler"
  type        = map(any)
  default = {
    requests = {
      cpu    = "100m"
      memory = "300Mi"
    }
    limits = {
      cpu    = "100m"
      memory = "300Mi"
    }
  }
}

variable "cluster_autoscaler_node_selector" {
  description = "Node selector for cluster autoscaler"
  type        = map(string)
  default = {
    "kubernetes.io/os" = "linux"
  }
}

variable "cluster_autoscaler_tolerations" {
  description = "Tolerations for cluster autoscaler"
  type        = list(any)
  default = [
    {
      key    = "CriticalAddonsOnly"
      operator = "Exists"
    },
    {
      effect = "NoSchedule"
      key    = "node-role.kubernetes.io/master"
    }
  ]
}

# KEDA
variable "enable_keda" {
  description = "Enable KEDA"
  type        = bool
  default     = false
}

variable "keda_namespace" {
  description = "Namespace for KEDA"
  type        = string
  default     = "keda"
}

variable "keda_version" {
  description = "Version of KEDA chart"
  type        = string
  default     = "2.12.1"
}

variable "keda_image_tag" {
  description = "Image tag for KEDA"
  type        = string
  default     = "2.12.1"
}

variable "keda_metrics_server_image_tag" {
  description = "Image tag for KEDA metrics server"
  type        = string
  default     = "2.12.1"
}

variable "keda_operator_resources" {
  description = "Resources for KEDA operator"
  type        = map(any)
  default = {
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "1000m"
      memory = "1000Mi"
    }
  }
}

variable "keda_metric_server_resources" {
  description = "Resources for KEDA metric server"
  type        = map(any)
  default = {
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "1000m"
      memory = "1000Mi"
    }
  }
}

variable "keda_node_selector" {
  description = "Node selector for KEDA"
  type        = map(string)
  default     = {}
}

variable "keda_tolerations" {
  description = "Tolerations for KEDA"
  type        = list(any)
  default     = []
}

# Azure Key Vault CSI Driver
variable "enable_azure_key_vault_csi" {
  description = "Enable Azure Key Vault CSI driver"
  type        = bool
  default     = true
}

variable "azure_key_vault_csi_namespace" {
  description = "Namespace for Azure Key Vault CSI driver"
  type        = string
  default     = "kube-system"
}

variable "azure_key_vault_csi_version" {
  description = "Version of Azure Key Vault CSI driver chart"
  type        = string
  default     = "1.4.4"
}

variable "azure_key_vault_csi_resources" {
  description = "Resources for Azure Key Vault CSI driver"
  type        = map(any)
  default = {
    requests = {
      cpu    = "50m"
      memory = "100Mi"
    }
    limits = {
      cpu    = "200m"
      memory = "200Mi"
    }
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = ""
}

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

variable "template_values" {
  description = "Enable templating for values files"
  type        = bool
  default     = true
}

variable "template_vars" {
  description = "Variables to pass to helm values templates"
  type        = map(string)
  default     = {}
}

