resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  dns_prefix          = "${var.project_name}-${var.environment}"
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                = "default"
    node_count          = var.node_count
    vm_size             = var.node_vm_size
    vnet_subnet_id      = azurerm_subnet.aks.id
    os_disk_size_gb     = 60
    os_disk_type        = "Managed"
    type                = "VirtualMachineScaleSets"
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 5
    max_pods            = 30

    node_labels = {
      "nodepool-type" = "system"
      "environment"   = var.environment
    }
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control_enabled = true
  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "calico"
    dns_service_ip     = "10.0.0.10"
    service_cidr       = "10.0.0.0/16"
    load_balancer_sku  = "standard"
    outbound_type      = "loadBalancer"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  azure_policy_enabled          = true
  http_application_routing_enabled = false

  api_server_access_profile {
    authorized_ip_ranges = var.api_server_authorized_ip_ranges
  }

  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [2, 3, 4]
    }
  }

  auto_scaler_profile {
    scan_interval                = "10s"
    scale_down_delay_after_add   = "10m"
    scale_down_unneeded          = "10m"
    skip_nodes_with_local_storage = false
  }

  tags = var.tags
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                       = "kv-${var.project_name}-${var.environment}"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = true
  enable_rbac_authorization  = true
  tags                       = var.tags

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
}
