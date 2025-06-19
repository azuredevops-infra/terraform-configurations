output "storage_account_id" {
  description = "The ID of the storage account"
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "The name of the storage account"
  value       = azurerm_storage_account.this.name
}

output "primary_blob_endpoint" {
  description = "The primary blob endpoint"
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "primary_file_endpoint" {
  description = "The primary file endpoint"
  value       = azurerm_storage_account.this.primary_file_endpoint
}

output "primary_access_key" {
  description = "The primary access key for the storage account"
  value       = azurerm_storage_account.this.primary_access_key
  sensitive   = true
}

output "containers" {
  description = "Map of containers and their attributes"
  value       = { for container in azurerm_storage_container.this : container.name => container.id }
}

output "file_shares" {
  description = "Map of file shares and their attributes"
  value       = { for share in azurerm_storage_share.this : share.name => share.id }
}

output "storage_class_azure_file" {
  description = "The name of the Azure File storage class"
  value       = var.create_kubernetes_storage_class && length(var.file_share_names) > 0 ? kubernetes_storage_class.azure_file[0].metadata[0].name : null
}

output "storage_class_azure_disk" {
  description = "The name of the Azure Disk storage class"
  value       = var.create_kubernetes_storage_class ? kubernetes_storage_class.azure_disk[0].metadata[0].name : null
}