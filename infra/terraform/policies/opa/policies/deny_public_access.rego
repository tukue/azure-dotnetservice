package terraform.deny_public_access

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_container_registry"
  resource.change.after.public_network_access_enabled == true

  msg := sprintf(
    "%s: ACR %s has public network access enabled. Set public_network_access_enabled = false.",
    [resource.address, resource.change.after.name],
  )
}

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_kubernetes_cluster"
  profile := resource.change.after.api_server_access_profile
  count(profile.authorized_ip_ranges) == 0

  msg := sprintf(
    "%s: AKS %s has no authorized IP ranges for the API server. Restrict access via authorized_ip_ranges.",
    [resource.address, resource.change.after.name],
  )
}

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_key_vault"
  resource.change.after.network_acls.default_action == "Allow"

  msg := sprintf(
    "%s: Key Vault %s allows public network traffic. Set default_action = \"Deny\".",
    [resource.address, resource.change.after.name],
  )
}
