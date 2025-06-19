output "namespace_id" {
  description = "The ID of the Service Bus namespace"
  value       = azurerm_servicebus_namespace.this.id
}

output "namespace_name" {
  description = "The name of the Service Bus namespace"
  value       = azurerm_servicebus_namespace.this.name
}

output "default_primary_connection_string" {
  description = "The primary connection string for the Service Bus namespace"
  value       = azurerm_servicebus_namespace.this.default_primary_connection_string
  sensitive   = true
}

output "topics" {
  description = "Map of created Service Bus topics"
  value       = { for k, v in azurerm_servicebus_topic.this : k => v.id }
}

output "queues" {
  description = "Map of created Service Bus queues"
  value       = { for k, v in azurerm_servicebus_queue.this : k => v.id }
}