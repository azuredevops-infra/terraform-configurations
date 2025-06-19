output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.this.name
}

output "kubernetes_cluster_name" {
  description = "The name of the AKS cluster"
  value       = module.aks.cluster_name
}

output "client_certificate" {
  description = "The client certificate for the AKS cluster"
  value       = module.aks.client_certificate
  sensitive   = true
}

output "client_key" {
  description = "The client key for the AKS cluster"
  value       = module.aks.client_key
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The CA certificate for the AKS cluster"
  value       = module.aks.cluster_ca_certificate
  sensitive   = true
}

output "host" {
  description = "The host for the AKS cluster"
  value       = module.aks.host
  sensitive   = true
}

output "kube_config" {
  description = "The kube config for the AKS cluster"
  value       = module.aks.kube_config
  sensitive   = true
}

output "oidc_issuer_url" {
  description = "The OIDC issuer URL of the AKS cluster"
  value       = module.aks.oidc_issuer_url
}

output "acr_login_server" {
  description = "The login server for the Azure Container Registry"
  value       = module.acr.login_server
}

output "vnet_id" {
  description = "The ID of the virtual network"
  value       = module.network.vnet_id
}

output "aks_subnet_id" {
  description = "The ID of the AKS subnet"
  value       = module.network.aks_subnet_id
}

output "key_vault_uri" {
  description = "The URI of the Key Vault"
  value       = module.key_vault.key_vault_uri
}

output "service_bus_namespace_name" {
  description = "The name of the Service Bus namespace"
  value       = module.service_bus.namespace_name
}

output "storage_account_name" {
  description = "The name of the storage account"
  value       = module.storage.storage_account_name
}

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace"
  value       = module.monitoring.log_analytics_workspace_id
}

output "grafana_endpoint" {
  description = "The endpoint of the Grafana dashboard"
  value       = var.enable_grafana ? module.monitoring.grafana_endpoint : null
}

output "application_insights_connection_string" {
  description = "The connection string of Application Insights"
  value       = module.monitoring.application_insights_connection_string
  sensitive   = true
}

output "firewall_private_ip" {
  description = "The private IP of the Azure Firewall"
  value       = var.enable_firewall ? module.firewall[0].firewall_private_ip : null
}

output "app_gateway_public_ip" {
  description = "The public IP address of the Application Gateway"
  value       = var.enable_app_gateway ? module.app_gateway[0].public_ip_address : null
}

output "bastion_dns_name" {
  description = "The DNS name of the Azure Bastion"
  value       = var.enable_bastion ? module.bastion[0].bastion_dns_name : null
}

output "management_vm_private_ip" {
  description = "The private IP of the management VM"
  value       = var.enable_bastion && var.create_management_vm ? module.bastion[0].management_vm_private_ip : null
}

# Enhanced outputs
output "cluster_access_config" {
  description = "Cluster access configuration"
  value = {
    cluster_name    = module.aks.cluster_name
    resource_group  = azurerm_resource_group.this.name
    subscription_id = data.azurerm_client_config.current.subscription_id
    tenant_id       = data.azurerm_client_config.current.tenant_id
    oidc_issuer_url = module.aks.oidc_issuer_url
  }
}

output "certificates_config" {
  description = "Certificate configuration"
  value = {
    certificates = module.key_vault.certificates
    dns_zone_ns  = module.key_vault.dns_zone_name_servers
  }
}

output "workload_identities" {
  description = "Workload identities"
  value = module.aks.workload_identities
}

output "network_config" {
  description = "Network configuration details"
  value = {
    vnet_id             = module.network.vnet_id
    vnet_name           = module.network.vnet_name
    aks_subnet_id       = module.network.aks_subnet_id
    private_subnet_id   = module.network.private_subnet_id
    nat_gateway_ips     = var.enable_nat_gateway ? module.network.nat_gateway_public_ips : []
  }
}