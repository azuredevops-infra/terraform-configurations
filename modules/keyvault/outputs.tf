output "key_vault_id" {
  description = "The ID of the Key Vault"
  value       = azurerm_key_vault.this.id
}

output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.this.name
}

output "key_vault_uri" {
  description = "The URI of the Key Vault"
  value       = azurerm_key_vault.this.vault_uri
}

output "certificates" {
  description = "Map of certificates created"
  value = {
    for k, v in azurerm_key_vault_certificate.app_certs : k => {
      id          = v.id
      name        = v.name
      secret_id   = v.secret_id
      version     = v.version
      thumbprint  = v.thumbprint
    }
  }
}

output "dns_zone_name_servers" {
  description = "Name servers for the DNS zone"
  value       = local.dns_zone != null ? local.dns_zone.name_servers : []
}