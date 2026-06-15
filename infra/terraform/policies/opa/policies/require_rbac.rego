package terraform.require_rbac

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_kubernetes_cluster"
  resource.change.after.role_based_access_control_enabled == false

  msg := sprintf(
    "%s: AKS %s must have role_based_access_control_enabled = true.",
    [resource.address, resource.change.after.name],
  )
}

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_kubernetes_cluster"
  resource.change.after.azure_active_directory_role_based_access_control.managed == false

  msg := sprintf(
    "%s: AKS %s must have Azure AD managed RBAC enabled.",
    [resource.address, resource.change.after.name],
  )
}

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_key_vault"
  resource.change.after.enable_rbac_authorization == false

  msg := sprintf(
    "%s: Key Vault %s must use RBAC authorization.",
    [resource.address, resource.change.after.name],
  )
}
