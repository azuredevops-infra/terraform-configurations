resource "random_string" "storage_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_storage_account" "this" {
  name                     = "${var.prefix}${var.environment}${random_string.storage_suffix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  min_tls_version          = "TLS1_2"
  tags                     = var.tags

  blob_properties {
    versioning_enabled = true

    container_delete_retention_policy {
      days = 7
    }

    delete_retention_policy {
      days = 7
    }
  }

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    ip_rules       = var.allowed_ips
  }
}

resource "azurerm_storage_container" "this" {
  for_each             = toset(var.container_names)
  name                 = each.value
  storage_account_id = azurerm_storage_account.this.id
  container_access_type = "private"
}

resource "azurerm_storage_management_policy" "this" {
  storage_account_id = azurerm_storage_account.this.id

  rule {
    name    = "lifecycle"
    enabled = true
    filters {
      prefix_match = ["backups/"]
      blob_types   = ["blockBlob"]
    }
    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = 30
        tier_to_archive_after_days_since_modification_greater_than = 90
        delete_after_days_since_modification_greater_than          = 365
      }
      snapshot {
        delete_after_days_since_creation_greater_than = 30
      }
      version {
        delete_after_days_since_creation = 90
      }
    }
  }
}

resource "azurerm_storage_share" "this" {
  for_each         = toset(var.file_share_names)
  name             = each.value
  storage_account_id = azurerm_storage_account.this.id
  quota            = var.file_share_quota
}

resource "azurerm_private_dns_zone" "blob" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_endpoint" "blob" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.prefix}-${var.environment}-blob-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.prefix}-${var.environment}-blob-connection"
    private_connection_resource_id = azurerm_storage_account.this.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob[0].id]
  }
}

resource "azurerm_private_dns_zone" "file" {
  count               = var.enable_private_endpoint && length(var.file_share_names) > 0 ? 1 : 0
  name                = "privatelink.file.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_endpoint" "file" {
  count               = var.enable_private_endpoint && length(var.file_share_names) > 0 ? 1 : 0
  name                = "${var.prefix}-${var.environment}-file-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.prefix}-${var.environment}-file-connection"
    private_connection_resource_id = azurerm_storage_account.this.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.file[0].id]
  }
}

# For Kubernetes integration with Azure Files
resource "kubernetes_storage_class" "azure_file" {
  count = var.create_kubernetes_storage_class && length(var.file_share_names) > 0 ? 1 : 0

  metadata {
    name = "azure-file"
  }

  storage_provisioner = "kubernetes.io/azure-file"
  reclaim_policy      = "Retain"
  parameters = {
    skuName        = var.storage_account_tier
    storageAccount = azurerm_storage_account.this.name
  }
  mount_options = ["file_mode=0777", "dir_mode=0777", "mfsymlinks", "uid=1000", "gid=1000"]

   lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

resource "kubernetes_storage_class" "azure_disk" {
  count = var.create_kubernetes_storage_class ? 1 : 0

  metadata {
    name = "azure-disk"
  }

  storage_provisioner = "kubernetes.io/azure-disk"
  reclaim_policy      = "Retain"
  parameters = {
    storageaccounttype = "${var.storage_account_tier}_${var.storage_account_replication_type}"
    kind               = "Managed"
  }

   lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

resource "kubernetes_secret" "azure_storage" {
  count = var.create_kubernetes_storage_class ? 1 : 0

  metadata {
    name = "azure-storage-secret"
  }

  data = {
    azurestorageaccountname = azurerm_storage_account.this.name
    azurestorageaccountkey  = azurerm_storage_account.this.primary_access_key
  }

  type = "Opaque"
}

# Enhanced Storage Classes
resource "kubernetes_storage_class_v1" "custom" {
  for_each = var.custom_storage_classes
  
  metadata {
    name        = each.key
    annotations = each.value.annotations
    labels      = each.value.labels
  }
  
  storage_provisioner    = each.value.provisioner
  reclaim_policy        = each.value.reclaim_policy
  volume_binding_mode   = each.value.volume_binding_mode
  allow_volume_expansion = each.value.allow_volume_expansion
  
  parameters = each.value.parameters
  
  mount_options = each.value.mount_options

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}