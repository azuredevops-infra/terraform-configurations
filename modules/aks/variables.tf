variable "prefix" {
  description = "The prefix for all resources"
  type        = string
}

variable "environment" {
  description = "The environment (dev, test, prod, etc.)"
  type        = string
}

variable "location" {
  description = "The Azure location where resources will be created"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "kubernetes_version" {
  description = "The Kubernetes version"
  type        = string
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


variable "node_count" {
  description = "The initial number of nodes in the node pool"
  type        = number
}

variable "vm_size" {
  description = "The size of the Virtual Machine"
  type        = string
}

variable "vnet_id" {
  description = "The ID of the virtual network"
  type        = string
}

variable "vnet_subnet_id" {
  description = "The ID of the subnet where the AKS will be deployed"
  type        = string
}

variable "acr_id" {
  description = "The ID of the Azure Container Registry"
  type        = string
}

variable "key_vault_id" {
  description = "The ID of the Key Vault"
  type        = string
}

variable "aad_admin_group_ids" {
  description = "List of Azure AD group object IDs that will have admin role of the cluster"
  type        = list(string)
  default     = []
}

variable "admin_username" {
  description = "The admin username for the Linux VMs"
  type        = string
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

# Replace the existing node_pools variable with this enhanced version
variable "node_pools" {
  description = "Map of node pool configurations"
  type = map(object({
    vm_size               = string
    node_count           = number
    enable_auto_scaling  = bool
    min_count           = number
    max_count           = number
    availability_zones   = optional(list(string), [])
    os_disk_size_gb     = optional(number, 100)
    os_disk_type        = optional(string, "Managed")
    os_type             = optional(string, "Linux")
    enable_host_encryption = optional(bool, false)
    fips_enabled        = optional(bool, false)
    kubelet_disk_type   = optional(string, "OS")
    max_pods            = optional(number, 110)
    priority            = optional(string, "Regular")
    eviction_policy     = optional(string, "Delete")
    spot_max_price      = optional(number, -1)
    max_surge           = optional(string, "33%")
    node_labels         = optional(map(string), {})
    node_taints         = optional(list(string), [])
    tags               = optional(map(string), {})
  }))
}

# Workload Identity Configuration
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

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}