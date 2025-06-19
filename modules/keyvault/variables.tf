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

variable "allowed_ips" {
  description = "List of allowed IP addresses for the Key Vault"
  type        = list(string)
  default     = []
}

variable "aks_subnet_id" {
  description = "The ID of the AKS subnet"
  type        = string
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint for the Key Vault"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "The ID of the subnet where the private endpoint will be created"
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

# Certificate Management Variables
variable "certificates_config" {
  description = "Configuration for certificates to create in Key Vault"
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