output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.this.id
}

output "log_analytics_workspace_primary_shared_key" {
  description = "The primary shared key of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.this.primary_shared_key
  sensitive   = true
}

output "application_insights_instrumentation_key" {
  description = "The instrumentation key of the Application Insights"
  value       = azurerm_application_insights.this.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "The connection string of Application Insights"
  value       = azurerm_application_insights.this.connection_string
  sensitive   = true
}

output "application_insights_app_id" {
  description = "The App ID of the Application Insights"
  value       = azurerm_application_insights.this.app_id
}
