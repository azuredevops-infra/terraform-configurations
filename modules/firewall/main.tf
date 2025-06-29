resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet" # Must be named exactly this
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = [var.firewall_subnet_cidr]
}

resource "azurerm_public_ip" "firewall" {
  name                = "${var.prefix}-${var.environment}-firewall-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall" "this" {
  name                = "${var.prefix}-${var.environment}-firewall"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}

# Add network rules for AKS - Fixed service tag
resource "azurerm_firewall_network_rule_collection" "aks" {
  name                = "aks-network-rules"
  azure_firewall_name = azurerm_firewall.this.name
  resource_group_name = var.resource_group_name
  priority            = 100
  action              = "Allow"

  rule {
    name                  = "allow-https"
    source_addresses      = [var.aks_subnet_cidr]
    destination_ports     = ["443"]
    destination_addresses = ["AzureCloud"]
    protocols             = ["TCP"]
  }

  rule {
    name                  = "allow-ntp"
    source_addresses      = [var.aks_subnet_cidr]
    destination_ports     = ["123"]
    destination_addresses = ["*"]
    protocols             = ["UDP"]
  }

  rule {
    name                  = "allow-dns"
    source_addresses      = [var.aks_subnet_cidr]
    destination_ports     = ["53"]
    destination_addresses = ["*"]
    protocols             = ["UDP"]
  }

  # Additional rules for AKS
  rule {
    name                  = "allow-azure-monitor"
    source_addresses      = [var.aks_subnet_cidr]
    destination_ports     = ["443"]
    destination_addresses = ["AzureMonitor"]
    protocols             = ["TCP"]
  }

  rule {
    name                  = "allow-storage"
    source_addresses      = [var.aks_subnet_cidr]
    destination_ports     = ["443"]
    destination_addresses = ["Storage"]
    protocols             = ["TCP"]
  }
}

# Add application rules for AKS
resource "azurerm_firewall_application_rule_collection" "aks" {
  name                = "aks-application-rules"
  azure_firewall_name = azurerm_firewall.this.name
  resource_group_name = var.resource_group_name
  priority            = 100
  action              = "Allow"

  rule {
    name             = "allow-aks-services"
    source_addresses = [var.aks_subnet_cidr]
    
    target_fqdns = [
      "*.azmk8s.io",
      "*.hcp.${var.location}.azmk8s.io",
      "*.tun.${var.location}.azmk8s.io",
      "mcr.microsoft.com",
      "*.data.mcr.microsoft.com",
      "*.cdn.mscr.io",
      "*.azurecr.io",
      "*.blob.core.windows.net",
      "*.azureedge.net",
      "login.microsoftonline.com",
      "packages.microsoft.com",
      "azurecliprod.blob.core.windows.net",
      "acs-mirror.azureedge.net"
    ]
    
    protocol {
      port = "443"
      type = "Https"
    }
  }

  rule {
    name             = "allow-ubuntu-updates"
    source_addresses = [var.aks_subnet_cidr]
    
    target_fqdns = [
      "security.ubuntu.com",
      "archive.ubuntu.com",
      "changelogs.ubuntu.com"
    ]
    
    protocol {
      port = "80"
      type = "Http"
    }
    
    protocol {
      port = "443"
      type = "Https"
    }
  }

  rule {
    name             = "allow-docker-registry"
    source_addresses = [var.aks_subnet_cidr]
    
    target_fqdns = [
      "*.docker.io",
      "*.docker.com",
      "production.cloudflare.docker.com"
    ]
    
    protocol {
      port = "443"
      type = "Https"
    }
  }
}