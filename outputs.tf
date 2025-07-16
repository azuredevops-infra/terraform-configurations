# ==============================================================================
# BASIC INFRASTRUCTURE OUTPUTS
# ==============================================================================

output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.this.name
}

output "kubernetes_cluster_name" {
  description = "The name of the AKS cluster"
  value       = module.aks.cluster_name
}

output "oidc_issuer_url" {
  description = "The OIDC issuer URL of the AKS cluster"
  value       = module.aks.oidc_issuer_url
}

# ==============================================================================
# APPLICATION ACCESS URLS
# ==============================================================================

output "application_urls" {
  description = "URLs for accessing deployed applications"
  value = {
    argocd     = "https://${var.grafana_domain}"
    keycloak   = "https://${var.grafana_domain}/auth"
    grafana    = var.enable_opensource_grafana ? "https://${var.grafana_domain}/grafana" : null
    prometheus = var.enable_opensource_prometheus ? "https://${var.grafana_domain}/prometheus" : null
  }
}

# ==============================================================================
# AUTHENTICATION & ACCESS
# ==============================================================================

output "access_credentials" {
  description = "Access credentials for applications"
  sensitive   = true
  value = {
    grafana = var.enable_opensource_grafana ? {
      url      = "https://${var.grafana_domain}/grafana"
      username = "admin"
      password = var.grafana_admin_password
    } : null
    
    cluster = {
      host                   = module.aks.host
      client_certificate     = module.aks.client_certificate
      client_key            = module.aks.client_key
      cluster_ca_certificate = module.aks.cluster_ca_certificate
      kube_config           = module.aks.kube_config
    }
  }
}

# ==============================================================================
# AZURE SERVICES
# ==============================================================================

output "azure_services" {
  description = "Azure service endpoints and identifiers"
  value = {
    acr_login_server               = module.acr.login_server
    key_vault_uri                  = module.key_vault.key_vault_uri
    storage_account_name           = module.storage.storage_account_name
    service_bus_namespace_name     = module.service_bus.namespace_name
    log_analytics_workspace_id    = module.monitoring.log_analytics_workspace_id
    application_insights_app_id    = module.monitoring.application_insights_app_id
  }
}

# ==============================================================================
# NETWORK CONFIGURATION
# ==============================================================================

output "network_config" {
  description = "Network configuration details"
  value = {
    vnet_id               = module.network.vnet_id
    vnet_name             = module.network.vnet_name
    aks_subnet_id         = module.network.aks_subnet_id
    private_subnet_id     = module.network.private_subnet_id
    app_gateway_public_ip = var.enable_app_gateway ? module.app_gateway[0].public_ip_address : null
    firewall_private_ip   = var.enable_firewall ? module.firewall[0].firewall_private_ip : null
    nat_gateway_ips       = var.enable_nat_gateway ? module.network.nat_gateway_public_ips : []
  }
}

# ==============================================================================
# MANAGEMENT & OPERATIONS
# ==============================================================================

output "management_config" {
  description = "Management and operational configuration"
  value = {
    bastion_dns_name          = var.enable_bastion ? module.bastion[0].bastion_dns_name : null
    management_vm_private_ip  = var.enable_bastion && var.create_management_vm ? module.bastion[0].management_vm_private_ip : null
    workload_identities       = module.aks.workload_identities
    certificates             = module.key_vault.certificates
    dns_zone_name_servers    = module.key_vault.dns_zone_name_servers
  }
}

# ==============================================================================
# MONITORING & OBSERVABILITY
# ==============================================================================

output "monitoring_config" {
  description = "Monitoring and observability configuration"
  value = {
    # Open Source Stack
    grafana_enabled    = var.enable_opensource_grafana
    prometheus_enabled = var.enable_opensource_prometheus
    grafana_url       = var.enable_opensource_grafana ? "https://${var.grafana_domain}/grafana" : null
    prometheus_url    = var.enable_opensource_prometheus ? "https://${var.grafana_domain}/prometheus" : null
    
    # Observability Stack (Loki, Tempo, Mimir)
    observability_stack_enabled = var.enable_observability_stack
    loki_enabled    = var.enable_loki
    tempo_enabled   = var.enable_tempo
    mimir_enabled   = var.enable_mimir
    
    # Observability URLs (if enabled)
    loki_url    = var.enable_loki ? "https://${var.grafana_domain}/loki" : null
    tempo_url   = var.enable_tempo ? "https://${var.grafana_domain}/tempo" : null
    mimir_url   = var.enable_mimir ? "https://${var.grafana_domain}/mimir" : null
  }
}

# ==============================================================================
# CLUSTER ACCESS INFORMATION
# ==============================================================================

output "cluster_access_info" {
  description = "Information needed to access the cluster"
  value = {
    cluster_name    = module.aks.cluster_name
    resource_group  = azurerm_resource_group.this.name
    subscription_id = data.azurerm_client_config.current.subscription_id
    tenant_id       = data.azurerm_client_config.current.tenant_id
    oidc_issuer_url = module.aks.oidc_issuer_url
    
    # Commands for quick access
    kubectl_config_command = "az aks get-credentials --resource-group ${azurerm_resource_group.this.name} --name ${module.aks.cluster_name}"
    
    # Application access
    applications = {
      argocd     = "https://${var.grafana_domain}"
      keycloak   = "https://${var.grafana_domain}/auth"
      grafana    = var.enable_opensource_grafana ? "https://${var.grafana_domain}/grafana" : null
      prometheus = var.enable_opensource_prometheus ? "https://${var.grafana_domain}/prometheus" : null
    }
  }
}

# ==============================================================================
# SENSITIVE CREDENTIALS (Separate output for security)
# ==============================================================================

output "sensitive_credentials" {
  description = "Sensitive connection strings and credentials"
  sensitive   = true
  value = {
    application_insights_connection_string = module.monitoring.application_insights_connection_string
    grafana_admin_password = var.enable_opensource_grafana ? var.grafana_admin_password : null
  }
}