# Azure AKS Cluster Module
# Creates AKS cluster with proper networking and security

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.cluster_name}-rg"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = var.cluster_name
    ManagedBy   = "terraform"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.cluster_name}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Environment = var.environment
    Project     = var.cluster_name
  }
}

# Subnet for AKS cluster
resource "azurerm_subnet" "aks" {
  name                 = "${var.cluster_name}-aks-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_cidr]
}

# Network Security Group
resource "azurerm_network_security_group" "aks" {
  name                = "${var.cluster_name}-aks-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSSH"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.admin_cidr
    destination_address_prefix = "*"
  }

  tags = {
    Environment = var.environment
    Project     = var.cluster_name
  }
}

# Associate NSG with subnet
resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

# Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.cluster_name}-workspace"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = var.environment
    Project     = var.cluster_name
  }
}

# AKS Cluster Identity
resource "azurerm_user_assigned_identity" "aks" {
  name                = "${var.cluster_name}-identity"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Environment = var.environment
    Project     = var.cluster_name
  }
}

# Role assignments for AKS identity
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = azurerm_virtual_network.main.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

resource "azurerm_role_assignment" "aks_monitoring_metrics_publisher" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${var.cluster_name}-k8s"
  kubernetes_version  = var.kubernetes_version

  # Default node pool
  default_node_pool {
    name                = "system"
    node_count          = var.system_node_count
    vm_size             = var.system_node_size
    vnet_subnet_id      = azurerm_subnet.aks.id
    enable_auto_scaling = true
    min_count           = var.system_min_nodes
    max_count           = var.system_max_nodes
    max_pods            = 110
    os_disk_size_gb     = 30
    os_disk_type        = "Managed"

    upgrade_settings {
      max_surge = "10%"
    }

    tags = {
      Environment = var.environment
      NodePool    = "system"
    }
  }

  # Identity configuration
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  # Network configuration
  network_profile {
    network_plugin     = "azure"
    network_policy     = "azure"
    dns_service_ip     = var.dns_service_ip
    service_cidr       = var.service_cidr
    load_balancer_sku  = "standard"
  }

  # RBAC configuration
  role_based_access_control_enabled = true

  # Azure AD integration
  azure_active_directory_role_based_access_control {
    managed                = true
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled     = true
  }

  # Monitoring
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }

  # Auto-scaler profile
  auto_scaler_profile {
    balance_similar_node_groups      = false
    expander                        = "random"
    max_graceful_termination_sec    = "600"
    max_node_provisioning_time      = "15m"
    max_unready_nodes              = 3
    max_unready_percentage         = 45
    new_pod_scale_up_delay         = "10s"
    scale_down_delay_after_add     = "10m"
    scale_down_delay_after_delete  = "10s"
    scale_down_delay_after_failure = "3m"
    scan_interval                  = "10s"
    scale_down_unneeded           = "10m"
    scale_down_unready            = "20m"
    scale_down_utilization_threshold = 0.5
  }

  # HTTP application routing
  http_application_routing_enabled = false

  # Key Vault secrets provider
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  # Maintenance windows
  maintenance_window {
    allowed {
      day   = "Saturday"
      hours = [2, 3, 4]
    }
    not_allowed {
      start = "2024-12-25T00:00:00Z"
      end   = "2024-12-26T00:00:00Z"
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.cluster_name
  }

  depends_on = [
    azurerm_role_assignment.aks_network_contributor,
    azurerm_role_assignment.aks_monitoring_metrics_publisher
  ]
}

# Additional node pools
resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  for_each = var.node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size              = each.value.vm_size
  node_count           = each.value.node_count
  vnet_subnet_id       = azurerm_subnet.aks.id

  enable_auto_scaling = each.value.enable_auto_scaling
  min_count          = each.value.min_count
  max_count          = each.value.max_count
  max_pods           = each.value.max_pods
  os_disk_size_gb    = each.value.os_disk_size_gb
  os_disk_type       = "Managed"
  priority           = each.value.priority
  spot_max_price     = each.value.priority == "Spot" ? each.value.spot_max_price : null

  node_taints = each.value.node_taints

  upgrade_settings {
    max_surge = "33%"
  }

  tags = {
    Environment = var.environment
    NodePool    = each.key
    Priority    = each.value.priority
  }
}

# Container Registry
resource "azurerm_container_registry" "main" {
  count               = var.enable_acr ? 1 : 0
  name                = "${replace(var.cluster_name, "-", "")}acr"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = false

  tags = {
    Environment = var.environment
    Project     = var.cluster_name
  }
}

# Attach ACR to AKS
resource "azurerm_role_assignment" "aks_acr_pull" {
  count                = var.enable_acr ? 1 : 0
  scope                = azurerm_container_registry.main[0].id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}