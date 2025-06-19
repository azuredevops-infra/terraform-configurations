resource "random_string" "sb_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_servicebus_namespace" "this" {
  name                = "${var.prefix}${var.environment}${random_string.sb_suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  capacity            = var.capacity
  tags                = var.tags
  #zone_redundant = var.sku == "Premium" ? true : false
}

resource "azurerm_servicebus_topic" "this" {
  for_each            = var.topics
  name                = each.key
  namespace_id        = azurerm_servicebus_namespace.this.id
  #enable_partitioning = var.sku == "Standard" ? true : false
}

resource "azurerm_servicebus_subscription" "this" {
  for_each = {
    for idx, val in flatten([
      for topic_key, subscriptions in var.topics : [
        for sub in subscriptions : {
          topic_key = topic_key
          sub_name  = sub
        }
      ]
    ]) : "${val.topic_key}_${val.sub_name}" => val
  }

  name               = each.value.sub_name
  topic_id           = azurerm_servicebus_topic.this[each.value.topic_key].id
  max_delivery_count = 10
}

resource "azurerm_servicebus_queue" "this" {
  for_each            = toset(var.queues)
  name                = each.value
  namespace_id        = azurerm_servicebus_namespace.this.id
  #enable_partitioning = var.sku == "Standard" ? true : false
}

resource "azurerm_private_dns_zone" "servicebus" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "privatelink.servicebus.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_endpoint" "servicebus" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.prefix}-${var.environment}-sb-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.prefix}-${var.environment}-sb-connection"
    private_connection_resource_id = azurerm_servicebus_namespace.this.id
    is_manual_connection           = false
    subresource_names              = ["namespace"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.servicebus[0].id]
  }
}