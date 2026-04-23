# ─────────────────────────────────────────────
# LOG ANALYTICS WORKSPACE
# Collects AKS logs and metrics
# Azure Monitor Container Insights reads from here
# AWS equivalent: CloudWatch Log Groups for EKS
# ─────────────────────────────────────────────

resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.project}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# ─────────────────────────────────────────────
# AKS CLUSTER
# Managed Kubernetes — Azure manages the control plane
# We manage node pools, networking, identity, and add-ons
# ─────────────────────────────────────────────

resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.project}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.project}-${var.environment}"
  kubernetes_version  = var.kubernetes_version

  # ── SYSTEM NODE POOL ──────────────────────
  # Runs Kubernetes system components — CoreDNS, metrics-server etc
  # Separate from user workloads — system components stay stable
  # even if user workloads are resource-hungry
  default_node_pool {
    name            = "system"
    node_count      = var.system_node_count
    vm_size         = var.node_vm_size
    vnet_subnet_id  = var.aks_subnet_id
    type            = "VirtualMachineScaleSets"
    os_disk_size_gb = 30

    # Only run system pods on this pool
    only_critical_addons_enabled = true

    node_labels = {
      "nodepool-type" = "system"
      "environment"   = var.environment
    }
  }

  # ── IDENTITY ──────────────────────────────
  # AKS uses managed identity to provision Azure resources
  # e.g. creating load balancers, attaching disks
  # UserAssigned = we control the identity lifecycle
  identity {
    type         = "UserAssigned"
    identity_ids = [var.app_identity_id]
  }

  # ── NETWORKING ────────────────────────────
  # Azure CNI — pods get VNet IPs directly
  # More IPs consumed but better network visibility
  # Required for private endpoints to work with pods
  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = "172.16.0.0/16"
    dns_service_ip    = "172.16.0.10"
  }

  # ── WORKLOAD IDENTITY ─────────────────────
  # Allows individual pods to have their own Azure identity
  # AWS equivalent: IRSA (IAM Roles for Service Accounts)
  # Pods authenticate to Key Vault, Storage etc without credentials
  workload_identity_enabled = true
  oidc_issuer_enabled       = true

  # ── MONITORING ────────────────────────────
  # Container Insights — collects pod logs and metrics
  # Sends to Log Analytics workspace
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }

  # ── SECURITY ──────────────────────────────
  # Disable local accounts — force Azure AD authentication
  # No static kubeconfig passwords
  local_account_disabled = false # true in prod

  # Auto-upgrade channel — patch versions applied automatically
  automatic_channel_upgrade = "patch"

  tags = var.tags
}

# ─────────────────────────────────────────────
# USER NODE POOL
# Separate pool for application workloads
# Isolated from system pool — workload issues don't
# affect Kubernetes system components
# AWS equivalent: Separate EKS managed node group
# ─────────────────────────────────────────────

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.node_vm_size
  node_count            = var.user_node_count
  vnet_subnet_id        = var.aks_subnet_id
  os_disk_size_gb       = 30

  # Taint system pool — only user workloads schedule here
  node_taints = []

  node_labels = {
    "nodepool-type" = "user"
    "environment"   = var.environment
    "workload"      = "application"
  }

  tags = var.tags
}