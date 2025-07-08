resource "azurerm_log_analytics_workspace" "this" {
  name                = "${var.prefix}-${var.environment}-law"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.log_analytics_workspace_sku
  retention_in_days   = var.retention_in_days
  tags                = var.tags
}

resource "azurerm_log_analytics_solution" "container_insights" {
  solution_name         = "ContainerInsights"
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.this.id
  workspace_name        = azurerm_log_analytics_workspace.this.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "${var.prefix}-${var.environment}-aks-diag"
  target_resource_id         = var.aks_cluster_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "kube-scheduler"
  }

  enabled_log {
    category = "kube-audit"
  }

  enabled_log {
    category = "cluster-autoscaler"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_application_insights" "this" {
  name                = "${var.prefix}-${var.environment}-appinsights"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"
  tags                = var.tags
}

resource "azurerm_monitor_action_group" "critical" {
  name                = "${var.prefix}-${var.environment}-critical-ag"
  resource_group_name = var.resource_group_name
  short_name          = "critical"
  tags                = var.tags

  email_receiver {
    name                    = "admin"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_metric_alert" "node_cpu" {
  name                = "${var.prefix}-${var.environment}-node-cpu-alert"
  resource_group_name = var.resource_group_name
  scopes              = [var.aks_cluster_id]
  description         = "Alert when CPU usage is high"
  severity            = 2
  window_size         = "PT5M"
  frequency           = "PT1M"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }

  action {
    action_group_id = azurerm_monitor_action_group.critical.id
  }

  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "node_memory" {
  name                = "${var.prefix}-${var.environment}-node-memory-alert"
  resource_group_name = var.resource_group_name
  scopes              = [var.aks_cluster_id]
  description         = "Alert when memory usage is high"
  severity            = 2
  window_size         = "PT5M"
  frequency           = "PT1M"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_memory_working_set_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }

  action {
    action_group_id = azurerm_monitor_action_group.critical.id
  }

  tags = var.tags
}

# Azure Monitor Workspace (required for Grafana integration)
resource "azurerm_monitor_workspace" "this" {
  count               = var.enable_grafana || var.enable_prometheus ? 1 : 0
  name                = "${var.prefix}-${var.environment}-amw"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# Azure Monitor for Prometheus - FIXED VERSION
resource "azurerm_monitor_data_collection_endpoint" "aks_metrics" {
  count               = var.enable_prometheus ? 1 : 0
  name                = "${var.prefix}-${var.environment}-aks-metrics-dce"
  resource_group_name = var.resource_group_name
  location            = var.location
  kind                = "Linux"
  tags                = var.tags
}

resource "azurerm_monitor_data_collection_rule" "aks_metrics" {
  count               = var.enable_prometheus ? 1 : 0
  name                = "${var.prefix}-${var.environment}-aks-metrics-dcr"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.aks_metrics[0].id

  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.this[0].id
      name              = "MonitoringAccount1"
    }
  }

  data_sources {
    prometheus_forwarder {
      name    = "PrometheusDataSource"
      streams = ["Microsoft-PrometheusMetrics"]
    }
  }

  data_flow {
    destinations = ["MonitoringAccount1"]
    streams      = ["Microsoft-PrometheusMetrics"]
  }
}

resource "azurerm_monitor_data_collection_rule_association" "aks_metrics" {
  count                   = var.enable_prometheus ? 1 : 0
  name                    = "${var.prefix}-${var.environment}-aks-metrics-dcra"
  target_resource_id      = var.aks_cluster_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.aks_metrics[0].id
}

# Azure Managed Grafana
resource "azurerm_dashboard_grafana" "this" {
  count                 = var.enable_grafana ? 1 : 0
  name                  = "${var.prefix}-${var.environment}-grafana"
  resource_group_name   = var.resource_group_name
  location              = var.location
  grafana_major_version = 11  

  identity {
    type = "SystemAssigned"
  }

  #Azure Monitor Workspace
  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.this[0].id
  }

  tags = var.tags
}

# Grant Grafana access to read monitoring data
resource "azurerm_role_assignment" "grafana_monitoring_reader" {
  count                = var.enable_grafana ? 1 : 0
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_dashboard_grafana.this[0].identity[0].principal_id
}

# Grant Grafana access to Azure Monitor Workspace
resource "azurerm_role_assignment" "grafana_monitor_workspace_reader" {
  count                = var.enable_grafana ? 1 : 0
  scope                = azurerm_monitor_workspace.this[0].id
  role_definition_name = "Monitoring Data Reader"
  principal_id         = azurerm_dashboard_grafana.this[0].identity[0].principal_id
}

# Get current Azure configuration
data "azurerm_client_config" "current" {}

# Assign current user as Grafana Admin
resource "azurerm_role_assignment" "grafana_admin_current_user" {
  count                = var.enable_grafana ? 1 : 0
  scope                = azurerm_dashboard_grafana.this[0].id
  role_definition_name = "Grafana Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Optional: Add additional users/groups
resource "azurerm_role_assignment" "grafana_admin_users" {
  for_each             = var.enable_grafana ? toset(var.grafana_admin_users) : []
  scope                = azurerm_dashboard_grafana.this[0].id
  role_definition_name = "Grafana Admin"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "grafana_viewer_users" {
  for_each             = var.enable_grafana ? toset(var.grafana_viewer_users) : []
  scope                = azurerm_dashboard_grafana.this[0].id
  role_definition_name = "Grafana Viewer"
  principal_id         = each.value
}



# Enable Defender for Cloud
resource "azurerm_security_center_subscription_pricing" "kubernetes" {
  count         = var.enable_defender ? 1 : 0
  tier          = "Standard"
  resource_type = "KubernetesService"
}

resource "azurerm_security_center_setting" "mcas_integration" {
  count        = var.enable_defender ? 1 : 0
  setting_name = "MCAS"
  enabled      = true
}