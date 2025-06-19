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

variable "address_space" {
  description = "The address space for the virtual network"
  type        = list(string)
}

variable "subnet_prefixes" {
  description = "The address prefixes for the subnets"
  type        = map(string)
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

# NAT Gateway Variables
variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for outbound traffic"
  type        = bool
  default     = false
}

variable "nat_gateway_count" {
  description = "Number of NAT Gateways to create"
  type        = number
  default     = 1
}

variable "nat_gateway_zones" {
  description = "Availability zones for NAT Gateway"
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "nat_gateway_idle_timeout" {
  description = "Idle timeout for NAT Gateway in minutes"
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