data "azurerm_resource_group" "main" {
  name = "rg-${var.project_name}-${var.environment}"
}

data "azurerm_policy_definition" "aks_rbac" {
  display_name = "Kubernetes clusters should be accessible only over HTTPS"
}

data "azurerm_policy_definition" "aks_authorized_ip" {
  display_name = "Authorized IP ranges should be defined on Kubernetes Services"
}

data "azurerm_policy_definition" "aks_defender" {
  display_name = "Azure Kubernetes Service clusters should have Defender profile enabled"
}

data "azurerm_policy_definition" "acr_encryption" {
  display_name = "Container registries should be encrypted with a customer-managed key"
}

data "azurerm_policy_definition" "kv_keys_expiry" {
  display_name = "Key Vault keys should have an expiration date"
}

resource "azurerm_policy_definition" "acr_admin_disabled" {
  name         = "acr-admin-user-disabled"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "ACR admin user should be disabled"

  policy_rule = jsonencode({
    if = {
      allOf = [
        { field = "type", equals = "Microsoft.ContainerRegistry/registries" },
        { field = "Microsoft.ContainerRegistry/registries/adminUserEnabled", equals = true }
      ]
    }
    then = { effect = "Deny" }
  })
}

resource "azurerm_policy_definition" "aks_rbac_enforced" {
  name         = "aks-rbac-enforced"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "AKS clusters should have RBAC enabled"

  policy_rule = jsonencode({
    if = {
      allOf = [
        { field = "type", equals = "Microsoft.ContainerService/managedClusters" },
        { field = "Microsoft.ContainerService/managedClusters/enableRBAC", equals = false }
      ]
    }
    then = { effect = "Deny" }
  })
}

resource "azurerm_policy_definition" "kv_purge_protection" {
  name         = "kv-purge-protection-enabled"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Key Vault purge protection should be enabled"

  policy_rule = jsonencode({
    if = {
      allOf = [
        { field = "type", equals = "Microsoft.KeyVault/vaults" },
        { field = "Microsoft.KeyVault/vaults/enablePurgeProtection", equals = false }
      ]
    }
    then = { effect = "Deny" }
  })
}

resource "azurerm_policy_set_definition" "aks_security_baseline" {
  name         = "aks-security-baseline"
  policy_type  = "Custom"
  display_name = "AKS Security Baseline Initiative"

  policy_definition_reference {
    policy_definition_id = data.azurerm_policy_definition.aks_rbac.id
  }
  policy_definition_reference {
    policy_definition_id = data.azurerm_policy_definition.aks_authorized_ip.id
  }
  policy_definition_reference {
    policy_definition_id = data.azurerm_policy_definition.aks_defender.id
  }
  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.aks_rbac_enforced.id
  }
}

resource "azurerm_resource_group_policy_assignment" "aks_baseline" {
  name                 = "aks-security-baseline"
  resource_group_id    = data.azurerm_resource_group.main.id
  policy_definition_id = azurerm_policy_set_definition.aks_security_baseline.id
  display_name         = "AKS Security Baseline"
}

resource "azurerm_resource_group_policy_assignment" "acr_admin_disabled" {
  name                 = "acr-admin-disabled"
  resource_group_id    = data.azurerm_resource_group.main.id
  policy_definition_id = azurerm_policy_definition.acr_admin_disabled.id
  display_name         = "ACR Admin User Disabled"
}

resource "azurerm_resource_group_policy_assignment" "kv_purge_protection" {
  name                 = "kv-purge-protection"
  resource_group_id    = data.azurerm_resource_group.main.id
  policy_definition_id = azurerm_policy_definition.kv_purge_protection.id
  display_name         = "Key Vault Purge Protection Enabled"
}

resource "azurerm_resource_group_policy_assignment" "acr_encryption" {
  name                 = "acr-cmk-encryption"
  resource_group_id    = data.azurerm_resource_group.main.id
  policy_definition_id = data.azurerm_policy_definition.acr_encryption.id
  display_name         = "ACR Customer-Managed Key Encryption"
}
