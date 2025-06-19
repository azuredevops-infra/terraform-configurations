output "bastion_id" {
  description = "The ID of the Azure Bastion"
  value       = azurerm_bastion_host.this.id
}

output "bastion_dns_name" {
  description = "The DNS name of the Azure Bastion"
  value       = azurerm_bastion_host.this.dns_name
}

output "management_vm_id" {
  description = "The ID of the management VM"
  value       = var.create_management_vm ? azurerm_linux_virtual_machine.management[0].id : null
}

output "management_vm_private_ip" {
  description = "The private IP of the management VM" 
  value       = var.create_management_vm ? azurerm_network_interface.management[0].private_ip_address : null
}