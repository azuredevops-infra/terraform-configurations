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

variable "vnet_name" {
  description = "The name of the virtual network"
  type        = string
}

variable "bastion_subnet_cidr" {
  description = "The CIDR for the Azure Bastion subnet"
  type        = string
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

variable "admin_username" {
  description = "The admin username for the management VM"
  type        = string
  default     = "azureadmin"
}

variable "ssh_public_key" {
  description = "The SSH public key for the management VM"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}