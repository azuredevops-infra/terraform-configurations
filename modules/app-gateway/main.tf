resource "azurerm_subnet" "appgw" {
  name                 = "${var.prefix}-${var.environment}-appgw-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = [var.subnet_cidr]
}

resource "azurerm_public_ip" "appgw" {
  name                = "${var.prefix}-${var.environment}-appgw-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# User Assigned Identity for Application Gateway
resource "azurerm_user_assigned_identity" "appgw" {
  name                = "${var.prefix}-${var.environment}-appgw-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# WAF Policy
resource "azurerm_web_application_firewall_policy" "this" {
  count               = var.enable_waf ? 1 : 0
  name                = "${var.prefix}-${var.environment}-waf-policy"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  policy_settings {
    enabled                     = true
    mode                        = var.waf_mode
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }

  #custom rules
  custom_rules {
    name      = "GeoBlockRule"
    priority  = 1
    rule_type = "MatchRule"
    action    = "Block"

    match_conditions {
      match_variables {
        variable_name = "RemoteAddr"
      }
      operator           = "GeoMatch"
      negation_condition = false
      match_values       = ["CN", "RU"] # Block China and Russia - modify as needed
    }
  }

  # Simple IP blocking rule instead of rate limiting
  custom_rules {
    name      = "BlockMaliciousIPs"
    priority  = 2
    rule_type = "MatchRule"
    action    = "Block"

    match_conditions {
      match_variables {
        variable_name = "RemoteAddr"
      }
      operator           = "IPMatch"
      negation_condition = false
      match_values       = ["192.0.2.0/24"] # Example malicious IP range - modify as needed
    }
  }
}

# Get current client configuration
data "azurerm_client_config" "current" {}

# Grant Key Vault access to the current user/service principal first
resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = var.key_vault_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  certificate_permissions = [
    "Get", "List", "Create", "Delete", "Update", "Import", "Backup", "Restore", "ManageContacts", "ManageIssuers", "GetIssuers", "ListIssuers", "SetIssuers", "DeleteIssuers"
  ]

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Backup", "Restore", "Recover", "Purge"
  ]

  key_permissions = [
    "Get", "List", "Create", "Delete", "Update", "Import", "Backup", "Restore", "Recover", "Purge"
  ]
}

# SSL Certificate (self-signed for demo)
resource "azurerm_key_vault_certificate" "appgw" {
  name         = "${var.prefix}-${var.environment}-appgw-cert"
  key_vault_id = var.key_vault_id

  certificate_policy {
    issuer_parameters {
      name = "Self"
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

      subject            = "CN=${var.prefix}-${var.environment}-appgw"
      validity_in_months = 12

      subject_alternative_names {
        dns_names = ["${var.prefix}-${var.environment}-appgw.local"]
      }
    }
  }

  depends_on = [azurerm_key_vault_access_policy.current_user]
}

resource "azurerm_application_gateway" "this" {
  name                = "${var.prefix}-${var.environment}-appgw"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  enable_http2        = true
  firewall_policy_id  = var.enable_waf ? azurerm_web_application_firewall_policy.this[0].id : null

  sku {
    name     = var.enable_waf ? "WAF_v2" : "Standard_v2"
    tier     = var.enable_waf ? "WAF_v2" : "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "${var.prefix}-${var.environment}-gateway-ip-configuration"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_port {
    name = "${var.prefix}-${var.environment}-frontend-port-http"
    port = 80
  }

  frontend_port {
    name = "${var.prefix}-${var.environment}-frontend-port-https"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "${var.prefix}-${var.environment}-frontend-ip-configuration"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  # Backend pool pointing to NGINX internal load balancer
  backend_address_pool {
    name         = "${var.prefix}-${var.environment}-nginx-backend"
    ip_addresses = ["10.0.1.5"]
  }

  # HTTP Settings for NGINX
  backend_http_settings {
    name                  = "${var.prefix}-${var.environment}-nginx-http-settings"
    cookie_based_affinity = "Disabled"
    #path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
    host_name            = "genesis-azure.d01.hdcss.com"
    pick_host_name_from_backend_address = false
    probe_name           = "${var.prefix}-${var.environment}-nginx-probe"
  }

  # Health probe for NGINX
  probe {
    name                = "${var.prefix}-${var.environment}-nginx-probe"
    protocol            = "Http"
    path                = "/healthz"
    host                = "genesis-azure.d01.hdcss.com"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    match {
      status_code = ["200"]
    }
  }

  # HTTP Listener
  http_listener {
    name                           = "${var.prefix}-${var.environment}-listener-http"
    frontend_ip_configuration_name = "${var.prefix}-${var.environment}-frontend-ip-configuration"
    frontend_port_name             = "${var.prefix}-${var.environment}-frontend-port-http"
    protocol                       = "Http"
  }

  # HTTPS Listener
  http_listener {
    name                           = "${var.prefix}-${var.environment}-listener-https"
    frontend_ip_configuration_name = "${var.prefix}-${var.environment}-frontend-ip-configuration"
    frontend_port_name             = "${var.prefix}-${var.environment}-frontend-port-https"
    protocol                       = "Https"
    ssl_certificate_name           = "${var.prefix}-${var.environment}-ssl-cert"
  }

  ssl_certificate {
    name                = "${var.prefix}-${var.environment}-ssl-cert"
    key_vault_secret_id = azurerm_key_vault_certificate.appgw.secret_id
  }

  # PATH-BASED ROUTING CONFIGURATION
  url_path_map {
    name                               = "${var.prefix}-${var.environment}-path-map"
    default_backend_address_pool_name  = "${var.prefix}-${var.environment}-nginx-backend"
    default_backend_http_settings_name = "${var.prefix}-${var.environment}-nginx-http-settings"

    # ArgoCD routing rule
    path_rule {
      name                       = "argocd-rule"
      paths                      = ["/admin", "/admin/*"]
      backend_address_pool_name  = "${var.prefix}-${var.environment}-nginx-backend"
      backend_http_settings_name = "${var.prefix}-${var.environment}-nginx-http-settings"
    }

    # Keycloak routing rule  
    path_rule {
      name                       = "keycloak-rule"
      paths                      = ["/auth", "/auth/*"]
      backend_address_pool_name  = "${var.prefix}-${var.environment}-nginx-backend"
      backend_http_settings_name = "${var.prefix}-${var.environment}-nginx-http-settings"
    }

    # Observability routing rule

    path_rule {
      name                       = "grafana-rule"
      paths                      = ["/grafana", "/grafana/*"]
      redirect_configuration_name = "${var.prefix}-${var.environment}-grafana-redirect"
    }

    path_rule {
      name                       = "loki-rule"
      paths                      = ["/loki", "/loki/*"]
      backend_address_pool_name  = "${var.prefix}-${var.environment}-nginx-backend"
      backend_http_settings_name = "${var.prefix}-${var.environment}-nginx-http-settings"
    }

    path_rule {
      name                       = "tempo-rule"
      paths                      = ["/tempo", "/tempo/*"]
      backend_address_pool_name  = "${var.prefix}-${var.environment}-nginx-backend"
      backend_http_settings_name = "${var.prefix}-${var.environment}-nginx-http-settings"
    }

    path_rule {
      name                       = "prometheus-rule"
      paths                      = ["/prometheus", "/prometheus/*"]
      backend_address_pool_name  = "${var.prefix}-${var.environment}-nginx-backend"
      backend_http_settings_name = "${var.prefix}-${var.environment}-nginx-http-settings"
    }
  }

  # HTTP to HTTPS redirect
  redirect_configuration {
    name                 = "${var.prefix}-${var.environment}-redirect-config"
    redirect_type        = "Permanent"
    target_listener_name = "${var.prefix}-${var.environment}-listener-https"
  }

  # Rewrite rule for Grafana
  redirect_configuration {
    name               = "${var.prefix}-${var.environment}-grafana-redirect"
    redirect_type      = "Permanent"
    target_url         = "https://${var.grafana_fqdn}"
    include_path       = false
    include_query_string = true
  }

  # HTTP request routing rule (redirect to HTTPS)
  request_routing_rule {
    name                        = "${var.prefix}-${var.environment}-request-routing-rule-http"
    rule_type                   = "Basic"
    http_listener_name          = "${var.prefix}-${var.environment}-listener-http"
    redirect_configuration_name = "${var.prefix}-${var.environment}-redirect-config"
    priority                    = 100
  }

  # HTTPS request routing rule with path-based routing
  request_routing_rule {
    name                       = "${var.prefix}-${var.environment}-request-routing-rule-https"
    rule_type                  = "PathBasedRouting"
    http_listener_name         = "${var.prefix}-${var.environment}-listener-https"
    url_path_map_name         = "${var.prefix}-${var.environment}-path-map"
    priority                   = 200
  }

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.appgw.id]
  }

  depends_on = [azurerm_key_vault_certificate.appgw]
}

#Grant Application Gateway User Assigned Identity access to Key Vault
resource "azurerm_key_vault_access_policy" "appgw" {
  key_vault_id = var.key_vault_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.appgw.principal_id  

  certificate_permissions = [
    "Get"
  ]

  secret_permissions = [
    "Get"
  ]

  depends_on = [azurerm_user_assigned_identity.appgw]
}