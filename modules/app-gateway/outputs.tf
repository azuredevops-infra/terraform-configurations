output "application_gateway_id" {
  description = "The ID of the Application Gateway"
  value       = azurerm_application_gateway.this.id
}

output "application_gateway_name" {
  description = "The name of the Application Gateway"
  value       = azurerm_application_gateway.this.name
}

output "public_ip_address" {
  description = "The public IP address of the Application Gateway"
  value       = azurerm_public_ip.appgw.ip_address
}

output "appgw_subnet_id" {
  description = "The ID of the Application Gateway subnet"
  value       = azurerm_subnet.appgw.id
}
