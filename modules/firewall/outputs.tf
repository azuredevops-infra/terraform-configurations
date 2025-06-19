output "firewall_id" {
  description = "The ID of the Azure Firewall"
  value       = azurerm_firewall.this.id
}

output "firewall_private_ip" {
  description = "The private IP of the Azure Firewall"
  value       = azurerm_firewall.this.ip_configuration[0].private_ip_address
}

output "firewall_public_ip" {
  description = "The public IP of the Azure Firewall"
  value       = azurerm_public_ip.firewall.ip_address
}