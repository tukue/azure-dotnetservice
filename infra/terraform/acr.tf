resource "azurerm_container_registry" "main" {
  name                = "cr${replace(var.project_name, "-", "")}${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.acr_sku
  admin_enabled       = false

  network_rule_set {
    default_action = "Deny"
  }

  public_network_access_enabled = true

  retention_policy {
    days = 30
    enabled = true
  }

  trust_policy {
    enabled = true
  }

  tags = var.tags
}
