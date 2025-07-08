variable "prefix" {
  description = "The prefix for all resources"
  type        = string
}

variable "environment" {
  description = "The environment (dev, test, prod, etc.)"
  type        = string
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "cluster_dependency" {
  description = "Dependency to ensure cluster is ready"
  type        = any
  default     = null
}

variable "namespace" {
  description = "Namespace for observability stack"
  type        = string
  default     = "observability"
}

# Storage configuration
variable "storage_account_name" {
  description = "Storage account name for persistent storage"
  type        = string
}

variable "storage_account_key" {
  description = "Storage account key"
  type        = string
  sensitive   = true
}

# Loki configuration
variable "enable_loki" {
  description = "Enable Loki for log aggregation"
  type        = bool
  default     = true
}

variable "loki_version" {
  description = "Loki Helm chart version"
  type        = string
  default     = "5.41.4"
}

variable "loki_retention_period" {
  description = "Log retention period"
  type        = string
  default     = "720h"  # 30 days
}

variable "loki_storage_size" {
  description = "Storage size for Loki"
  type        = string
  default     = "100Gi"
}

# Tempo configuration
variable "enable_tempo" {
  description = "Enable Tempo for distributed tracing"
  type        = bool
  default     = true
}

variable "tempo_version" {
  description = "Tempo Helm chart version"
  type        = string
  default     = "1.6.2"
}

variable "tempo_storage_size" {
  description = "Storage size for Tempo"
  type        = string
  default     = "50Gi"
}

variable "tempo_retention_period" {
  description = "Trace retention period"
  type        = string
  default     = "168h"  # 7 days
}

# Mimir configuration
variable "enable_mimir" {
  description = "Enable Mimir for long-term metrics storage"
  type        = bool
  default     = true
}

variable "mimir_version" {
  description = "Mimir Helm chart version"
  type        = string
  default     = "5.2.3"
}

variable "mimir_storage_size" {
  description = "Storage size for Mimir"
  type        = string
  default     = "200Gi"
}

variable "mimir_retention_period" {
  description = "Metrics retention period"
  type        = string
  default     = "8760h"  # 1 year
}

# Promtail configuration
variable "enable_promtail" {
  description = "Enable Promtail for log collection"
  type        = bool
  default     = true
}

variable "promtail_version" {
  description = "Promtail Helm chart version"
  type        = string
  default     = "6.15.5"
}

# OpenTelemetry configuration
variable "enable_otel_collector" {
  description = "Enable OpenTelemetry Collector"
  type        = bool
  default     = true
}

variable "otel_collector_version" {
  description = "OpenTelemetry Collector Helm chart version"
  type        = string
  default     = "0.81.0"
}

# Resource configuration
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

variable "node_selector" {
  description = "Node selector for observability workloads"
  type        = map(string)
  default     = {}
}

variable "tolerations" {
  description = "Tolerations for observability workloads"
  type        = list(any)
  default     = []
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}