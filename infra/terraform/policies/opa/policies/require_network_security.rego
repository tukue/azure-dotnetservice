package terraform.require_network_security

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_container_registry"
  resource.change.after.network_rule_set.default_action == "Allow"

  msg := sprintf(
    "%s: ACR %s must have network_rule_set.default_action = \"Deny\".",
    [resource.address, resource.change.after.name],
  )
}

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_key_vault"
  not resource.change.after.purge_protection_enabled

  msg := sprintf(
    "%s: Key Vault %s must have purge_protection_enabled = true.",
    [resource.address, resource.change.after.name],
  )
}

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_key_vault"
  not resource.change.after.soft_delete_retention_days >= 7

  msg := sprintf(
    "%s: Key Vault %s must have soft_delete_retention_days >= 7.",
    [resource.address, resource.change.after.name],
  )
}
