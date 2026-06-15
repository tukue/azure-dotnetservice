package terraform.require_encryption

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_container_registry"
  resource.change.after.sku != "Premium"

  msg := sprintf(
    "%s: ACR %s must use Premium SKU for encryption and network rules.",
    [resource.address, resource.change.after.name],
  )
}

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_kubernetes_cluster"
  not resource.change.after.oms_agent.log_analytics_workspace_id

  msg := sprintf(
    "%s: AKS %s must have OMS Agent (Azure Monitor) enabled for audit logging.",
    [resource.address, resource.change.after.name],
  )
}
