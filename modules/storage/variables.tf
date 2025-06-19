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

variable "container_names" {
  description = "The names of the containers to create"
  type        = list(string)
  default     = ["data", "backups", "artifacts"]
}

variable "file_share_names" {
  description = "The names of the file shares to create"
  type        = list(string)
  default     = ["config", "persistent"]
}

variable "file_share_quota" {
  description = "The quota in GB for the file shares"
  type        = number
  default     = 50
}

variable "allowed_ips" {
  description = "List of allowed IP addresses for the storage account"
  type        = list(string)
  default     = []
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint for the storage account"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "The ID of the subnet where the private endpoint will be created"
  type        = string
  default     = null
}

variable "aks_cluster_id" {
  description = "AKS cluster ID for dependency"
  type        = string
  default     = ""
}

variable "create_kubernetes_storage_class" {
  description = "Create Kubernetes storage classes"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

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