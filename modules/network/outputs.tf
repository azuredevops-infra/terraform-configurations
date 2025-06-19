output "vnet_id" {
  description = "The ID of the virtual network"
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "The name of the virtual network"
  value       = azurerm_virtual_network.this.name
}

output "aks_subnet_id" {
  description = "The ID of the AKS subnet"
  value       = azurerm_subnet.aks.id
}

output "private_subnet_id" {
  description = "The ID of the private subnet"
  value       = azurerm_subnet.private.id
}

output "aks_nsg_id" {
  description = "The ID of the AKS network security group"
  value       = azurerm_network_security_group.aks.id
}

output "aks_route_table_name" {
  description = "The name of the AKS route table"
  value       = azurerm_route_table.aks.name
}
output "aks_route_table_id" {
  description = "The ID of the AKS route table"
  value       = azurerm_route_table.aks.id
}

output "private_route_table_id" {
  description = "The ID of the private subnet route table"
  value       = azurerm_route_table.private.id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = azurerm_nat_gateway.main[*].id
}

output "nat_gateway_public_ips" {
  description = "Public IPs of the NAT Gateways"
  value       = azurerm_public_ip.nat[*].ip_address
}