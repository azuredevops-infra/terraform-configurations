resource "azurerm_resource_group" "this" {
  name     = "${var.prefix}-${var.environment}-rg"
  location = var.location
  tags     = var.tags
}

module "network" {
  source = "./modules/network"

  prefix              = var.prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.address_space
  subnet_prefixes     = var.subnet_prefixes
  enable_nat_gateway           = var.enable_nat_gateway
  nat_gateway_count           = var.nat_gateway_count
  nat_gateway_zones           = var.nat_gateway_zones
  nat_gateway_idle_timeout    = var.nat_gateway_idle_timeout
  associate_nat_gateway_to_aks = var.associate_nat_gateway_to_aks
  custom_network_rules        = var.custom_network_rules
  tags                = var.tags
}

module "firewall" {
  source = "./modules/firewall"
  count  = var.enable_firewall ? 1 : 0

  prefix               = var.prefix
  environment          = var.environment
  location             = var.location
  resource_group_name  = azurerm_resource_group.this.name
  vnet_name            = module.network.vnet_name
  firewall_subnet_cidr = var.firewall_subnet_cidr
  aks_subnet_cidr      = var.subnet_prefixes["aks"]
  tags                 = var.tags
}

# Create route for egress traffic via firewall

resource "azurerm_route" "internet_via_fw" {
  count                  = var.enable_firewall_route ? 1 : 0
  name                   = "internet-via-firewall"
  resource_group_name    = azurerm_resource_group.this.name
  route_table_name       = module.network.aks_route_table_name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.firewall_private_ip
  depends_on = [module.firewall, module.network]
}

module "acr" {
  source = "./modules/acr"

  prefix                     = var.prefix
  environment                = var.environment
  location                   = var.location
  resource_group_name        = azurerm_resource_group.this.name
  sku                        = var.acr_sku
  geo_replications           = var.acr_geo_replications
  enable_private_endpoint    = var.enable_private_endpoints
  private_endpoint_subnet_id = module.network.private_subnet_id
  tags                       = var.tags
}

module "key_vault" {
  source = "./modules/keyvault"

  prefix                     = var.prefix
  environment                = var.environment
  location                   = var.location
  resource_group_name        = azurerm_resource_group.this.name
  allowed_ips                = var.key_vault_allowed_ips
  enable_private_endpoint    = var.enable_private_endpoints
  private_endpoint_subnet_id = module.network.private_subnet_id
  aks_subnet_id              = module.network.aks_subnet_id
  certificates_config      = var.certificates_config
  root_domain             = var.root_domain
  create_dns_zone         = var.create_dns_zone
  dns_zone_resource_group = var.dns_zone_resource_group
  tags                       = var.tags
}

module "aks" {
  source = "./modules/aks"

  prefix                      = var.prefix
  environment                 = var.environment
  location                    = var.location
  resource_group_name         = azurerm_resource_group.this.name
  kubernetes_version          = var.kubernetes_version
  node_count                  = var.node_count
  vm_size                     = var.vm_size
  vnet_id                     = module.network.vnet_id
  vnet_subnet_id              = module.network.aks_subnet_id
  acr_id                      = module.acr.acr_id
  key_vault_id                = module.key_vault.key_vault_id
  admin_username              = var.admin_username
  ssh_public_key              = var.ssh_public_key
  enable_auto_scaling         = var.enable_auto_scaling
  min_count                   = var.min_count
  max_count                   = var.max_count
  private_cluster_enabled     = var.private_cluster_enabled
  enable_node_pools           = var.enable_node_pools
  node_pools                  = var.node_pools
  enable_gpu                  = var.enable_gpu
  gpu_node_count               = var.gpu_node_count
  gpu_min_count               = var.gpu_min_count
  gpu_max_count               = var.gpu_max_count
  workload_identities         = var.workload_identities
  k8s_cluster_roles           = var.k8s_cluster_roles
  k8s_roles                   = var.k8s_roles
  k8s_cluster_role_bindings   = var.k8s_cluster_role_bindings
  k8s_role_bindings           = var.k8s_role_bindings
  tags                        = var.tags
  depends_on                  = [module.network, module.acr, module.key_vault]
}

module "service_bus" {
  source = "./modules/servicebus"

  prefix                     = var.prefix
  environment                = var.environment
  location                   = var.location
  resource_group_name        = azurerm_resource_group.this.name
  sku                        = var.service_bus_sku
  capacity                   = var.service_bus_capacity
  topics                     = var.service_bus_topics
  queues                     = var.service_bus_queues
  enable_private_endpoint    = var.enable_private_endpoints
  private_endpoint_subnet_id = module.network.private_subnet_id
  tags                       = var.tags
}

module "storage" {
  source = "./modules/storage"

  prefix                              = var.prefix
  environment                         = var.environment
  location                            = var.location
  resource_group_name                 = azurerm_resource_group.this.name
  storage_account_tier                = var.storage_account_tier
  storage_account_replication_type    = var.storage_account_replication_type
  container_names                     = var.storage_container_names
  file_share_names                    = var.storage_file_share_names
  file_share_quota                    = var.storage_file_share_quota
  allowed_ips                         = var.storage_allowed_ips
  enable_private_endpoint             = var.enable_private_endpoints
  private_endpoint_subnet_id          = module.network.private_subnet_id
  create_kubernetes_storage_class     = true
  aks_cluster_id = module.aks.cluster_id
  custom_storage_classes = var.custom_storage_classes
  tags                                = var.tags
  depends_on = [module.aks]
}

module "monitoring" {
  source = "./modules/monitoring"

  prefix                      = var.prefix
  environment                 = var.environment
  location                    = var.location
  resource_group_name         = azurerm_resource_group.this.name
  aks_cluster_id              = module.aks.cluster_id
  log_analytics_workspace_sku = var.log_analytics_workspace_sku
  retention_in_days           = var.log_retention_in_days
  alert_email                 = var.alert_email
  enable_grafana              = var.enable_grafana
  enable_prometheus           = var.enable_prometheus
  enable_defender             = var.enable_defender
  tags                        = var.tags
}

module "app_gateway" {
  source = "./modules/app-gateway"
  count  = var.enable_app_gateway ? 1 : 0

  prefix                  = var.prefix
  environment             = var.environment
  location                = var.location
  resource_group_name     = azurerm_resource_group.this.name
  vnet_name               = module.network.vnet_name
  vnet_id                 = module.network.vnet_id
  subnet_cidr             = var.app_gateway_subnet_cidr
  aks_ingress_ip          = var.app_gateway_private_ip
  key_vault_id            = module.key_vault.key_vault_id
  enable_waf              = var.enable_waf
  waf_mode                = var.waf_mode
  tags                    = var.tags
}

module "bastion" {
  source = "./modules/bastion"
  count  = var.enable_bastion ? 1 : 0

  prefix                  = var.prefix
  environment             = var.environment
  location                = var.location
  resource_group_name     = azurerm_resource_group.this.name
  vnet_name               = module.network.vnet_name
  bastion_subnet_cidr     = var.bastion_subnet_cidr
  create_management_vm    = var.create_management_vm
  management_subnet_cidr  = var.management_subnet_cidr
  admin_username          = var.admin_username
  ssh_public_key          = var.ssh_public_key
  tags                    = var.tags
}

module "helm" {
  source = "./modules/helm"
  count  = var.enable_helm_charts && var.deploy_helm_charts ? 1 : 0

  environment     = var.environment
  helm_releases   = var.helm_releases
  template_values = var.helm_template_values
  
  /* template_vars   = merge(
    var.helm_template_vars,
    {
      acr_login_server = module.acr.login_server
      key_vault_uri    = module.key_vault.key_vault_uri
      certificates     = module.key_vault.certificates
    } 

  )*/

  # Cluster information
  cluster_name         = module.aks.cluster_name
  resource_group_name  = azurerm_resource_group.this.name
  node_resource_group  = module.aks.node_resource_group
  subscription_id      = data.azurerm_client_config.current.subscription_id
  tenant_id           = data.azurerm_client_config.current.tenant_id

  # Dependency to ensure AKS is ready
  cluster_dependency = module.aks.cluster_id

  # Enable/disable specific Helm charts
  enable_nginx_ingress        = var.enable_nginx_ingress
  enable_cert_manager         = var.enable_cert_manager
  enable_external_dns         = var.enable_external_dns
  enable_prometheus_stack     = var.enable_prometheus_stack
  enable_argocd              = var.enable_argocd
  enable_velero = var.enable_velero
  enable_cluster_autoscaler  = var.enable_cluster_autoscaler
  enable_keda                = var.enable_keda
  enable_azure_key_vault_csi = var.enable_azure_key_vault_csi

  # Velero configuration (if using Helm instead of separate module)
  velero_storage_account = var.enable_velero ? module.storage.storage_account_name : ""
  velero_client_id      = var.enable_velero ? module.aks.identity_principal_id : ""

  # External DNS configuration
  external_dns_domain_filters = var.external_dns_domain_filters
  external_dns_client_id     = var.external_dns_client_id
  external_dns_client_secret = var.external_dns_client_secret

  # Cluster Autoscaler configuration
  cluster_autoscaler_client_id = module.aks.identity_principal_id

  providers = {
    kubernetes = kubernetes
    helm       = helm
  }

  depends_on = [module.aks]

}
