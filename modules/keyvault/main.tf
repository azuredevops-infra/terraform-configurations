resource "random_string" "kv_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_key_vault" "this" {
  name                        = "${var.prefix}-${var.environment}-kv-${random_string.kv_suffix.result}"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"
  tags                        = var.tags

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = var.allowed_ips
    virtual_network_subnet_ids = [var.aks_subnet_id]
  }
}

# Grant access to current user/service principal
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get", "List", "Create", "Delete", "Update", "Purge"
  ]
  secret_permissions = [
    "Get", "List", "Set", "Delete", "Purge"
  ]
  certificate_permissions = [
    "Get", "List", "Create", "Delete", "Update", "Import", "Purge"
  ]
}

resource "azurerm_private_dns_zone" "kv" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_endpoint" "kv" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.prefix}-${var.environment}-kv-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.prefix}-${var.environment}-kv-connection"
    private_connection_resource_id = azurerm_key_vault.this.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.kv[0].id]
  }
}

# Certificate Management
resource "azurerm_key_vault_certificate" "app_certs" {
  for_each     = var.certificates_config
  name         = "${replace(each.key, ".", "-")}-cert"
  key_vault_id = azurerm_key_vault.this.id

  certificate_policy {
    issuer_parameters {
      name = each.value.issuer
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject            = "CN=${each.key}"
      validity_in_months = each.value.validity_months

      subject_alternative_names {
        dns_names = concat([each.key], each.value.san_names)
      }
    }
  }

  tags = var.tags
}

# DNS Zone Management (optional)
resource "azurerm_dns_zone" "main" {
  count               = var.create_dns_zone ? 1 : 0
  name                = var.root_domain
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

data "azurerm_dns_zone" "existing" {
  count               = var.create_dns_zone ? 0 : (var.root_domain != "" ? 1 : 0)
  name                = var.root_domain
  resource_group_name = var.dns_zone_resource_group != "" ? var.dns_zone_resource_group : var.resource_group_name
}

locals {
  dns_zone = var.root_domain != "" ? (
    var.create_dns_zone ? azurerm_dns_zone.main[0] : data.azurerm_dns_zone.existing[0]
  ) : null
}

# DNS Records
resource "azurerm_dns_a_record" "app_records" {
  for_each = { 
    for k, v in var.certificates_config : k => v 
    if v.create_dns_record && local.dns_zone != null && var.root_domain != ""
  }
  
  name                = each.value.dns_record_name
  zone_name           = local.dns_zone.name
  resource_group_name = local.dns_zone.resource_group_name
  ttl                 = each.value.dns_ttl
  records             = each.value.dns_records
  tags                = var.tags
}