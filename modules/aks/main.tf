data "azurerm_client_config" "current" {}
resource "azurerm_user_assigned_identity" "aks" {
  name                = "${var.prefix}-${var.environment}-aks-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_role_assignment" "aks_network" {
  scope                = var.vnet_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

resource "azurerm_role_assignment" "aks_acr" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

resource "azurerm_role_assignment" "aks_key_vault" {
  scope                = var.key_vault_id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

resource "random_string" "dns_prefix" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_private_dns_zone" "aks" {
  count               = var.private_cluster_enabled ? 1 : 0
  name                = "privatelink.${var.location}.azmk8s.io"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}
#Use system private DNS zone as I don't have permissions to create private DNS zones
resource "azurerm_private_dns_zone_virtual_network_link" "aks" {
  count                 = var.private_cluster_enabled ? 1 : 0
  name                  = "${var.prefix}-${var.environment}-aks-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.aks[0].name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_kubernetes_cluster" "this" {
  name                      = "${var.prefix}-${var.environment}-aks"
  location                  = var.location
  resource_group_name       = var.resource_group_name
  dns_prefix                = "${var.prefix}-${var.environment}-${random_string.dns_prefix.result}"
  kubernetes_version        = var.kubernetes_version
  tags                      = var.tags
  private_cluster_enabled   = var.private_cluster_enabled
  # private_dns_zone_id     = "System" # Use system private DNS zone as I don't have permissions to create private DNS zones
  private_dns_zone_id     = var.private_cluster_enabled ? azurerm_private_dns_zone.aks[0].id : null
  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  local_account_disabled    = false

  default_node_pool {
    name                = "system"
    node_count          = var.enable_auto_scaling ? null : var.node_count
    vm_size             = var.vm_size
    vnet_subnet_id      = var.vnet_subnet_id
    auto_scaling_enabled = var.enable_auto_scaling
    min_count           = var.enable_auto_scaling ? var.min_count : null
    max_count           = var.enable_auto_scaling ? var.max_count : null
    os_disk_size_gb     = 50
    type                = "VirtualMachineScaleSets"
    node_labels = {
      "nodepool-type" = "system"
      "environment"   = var.environment
    }
    #enable_host_encryption = true
    max_pods               = 110
    ultra_ssd_enabled      = false
    upgrade_settings {
      max_surge = "33%"
    }
    tags = var.tags
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.aks.id
    ]
  }

  linux_profile {
    admin_username = var.admin_username
    ssh_key {
      key_data = var.ssh_public_key
    }
  }

  network_profile {
    network_plugin      = "azure"
    network_policy      = "calico"
    load_balancer_sku   = "standard"
    service_cidr        = "10.1.0.0/16"
    dns_service_ip      = "10.1.0.10"
    network_plugin_mode = "overlay"
    pod_cidr            = "10.244.0.0/16"
  }

  azure_policy_enabled = true

    azure_active_directory_role_based_access_control {
    # managed = true
    azure_rbac_enabled = false
    tenant_id          = data.azurerm_client_config.current.tenant_id
    admin_group_object_ids = length(var.aad_admin_group_ids) > 0 ? var.aad_admin_group_ids : null
  }


  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [0, 1, 2, 3, 4]
    }
  }

  #automatic_channel_upgrade = "stable"

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  }

  microsoft_defender {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  }

  depends_on = [
    azurerm_role_assignment.aks_network,
    azurerm_role_assignment.aks_acr,
    azurerm_role_assignment.aks_key_vault
  ]

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
      kubernetes_version
    ]
  }
}

# Create additional node pools
resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  for_each = var.enable_node_pools ? var.node_pools : {}

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size              = each.value.vm_size
  
  # Availability zones
  zones = each.value.availability_zones
  
  # Scaling configuration
  auto_scaling_enabled  = each.value.enable_auto_scaling
  node_count         = each.value.enable_auto_scaling ? null : each.value.node_count
  min_count          = each.value.enable_auto_scaling ? each.value.min_count : null
  max_count          = each.value.enable_auto_scaling ? each.value.max_count : null
  
  # Advanced configuration
  vnet_subnet_id         = var.vnet_subnet_id
  os_disk_size_gb       = each.value.os_disk_size_gb
  os_disk_type          = each.value.os_disk_type
  os_type               = each.value.os_type
  #enable_host_encryption = each.value.enable_host_encryption (only for cluster level not ind node pools)
  fips_enabled          = each.value.fips_enabled
  kubelet_disk_type     = each.value.kubelet_disk_type
  max_pods              = each.value.max_pods
  
  # Spot/Priority configuration
  priority        = each.value.priority
  eviction_policy = each.value.priority == "Spot" ? each.value.eviction_policy : null
  spot_max_price  = each.value.priority == "Spot" ? each.value.spot_max_price : null
  
  # Update configuration
  upgrade_settings {
    max_surge = each.value.max_surge
  }
  
  # Labels and taints
  node_labels = each.value.node_labels
  node_taints = each.value.node_taints
  
  tags = merge(var.tags, each.value.tags)
}

# Additional Managed Identities for Workloads
resource "azurerm_user_assigned_identity" "workload_identities" {
  for_each            = var.workload_identities
  name                = "${var.prefix}-${var.environment}-${each.key}-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# Role Assignments for Workload Identities
resource "azurerm_role_assignment" "workload_assignments" {
  for_each = {
    for item in flatten([
      for identity_key, config in var.workload_identities : [
        for assignment in config.role_assignments : {
          key                  = "${identity_key}-${assignment.scope_type}-${assignment.role}"
          identity_key         = identity_key
          scope                = assignment.scope
          role_definition_name = assignment.role
        }
      ]
    ]) : item.key => item
  }
  
  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = azurerm_user_assigned_identity.workload_identities[each.value.identity_key].principal_id
}

# Federated Credentials for Workload Identity
resource "azurerm_federated_identity_credential" "workload" {
  for_each = {
    for item in flatten([
      for identity_key, config in var.workload_identities : [
        for cred in config.federated_credentials : {
          key              = "${identity_key}-${cred.name}"
          identity_key     = identity_key
          name            = cred.name
          subject         = cred.subject
          audience        = cred.audience
        }
      ] if config.federated_credentials != null
    ]) : item.key => item
  }

  name                = each.value.name
  resource_group_name = var.resource_group_name
  parent_id          = azurerm_user_assigned_identity.workload_identities[each.value.identity_key].id
  audience           = [each.value.audience]
  subject            = each.value.subject
  issuer             = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

/* Not availabe in East US region
# Pod Identity Extension
resource "azurerm_kubernetes_cluster_extension" "pod_identity" {
  name           = "pod-identity"
  cluster_id     = azurerm_kubernetes_cluster.this.id
  extension_type = "Microsoft.Azure.PodIdentity"
}

# User assigned identity for pod identity
resource "azurerm_user_assigned_identity" "pod_identity" {
  name                = "${var.prefix}-${var.environment}-pod-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# Role assignment for pod identity
resource "azurerm_role_assignment" "pod_identity_operator" {
  scope                = azurerm_user_assigned_identity.pod_identity.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

# Workload Identity Extension
resource "azurerm_kubernetes_cluster_extension" "workload_identity" {
  name           = "workload-identity"
  cluster_id     = azurerm_kubernetes_cluster.this.id
  extension_type = "Microsoft.WorkloadIdentity"
}
*/
# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "this" {
  name                = "${var.prefix}-${var.environment}-law"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}


resource "azurerm_log_analytics_solution" "this" {
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