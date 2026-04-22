# ─────────────────────────────────────────────
# HUB VIRTUAL NETWORK
# Shared services network — security, connectivity
# On a real engagement: connects to client on-prem via VPN/ExpressRoute
# ─────────────────────────────────────────────

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-${var.project}-hub-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.hub_vnet_cidr]
  tags                = var.tags
}

# Gateway subnet — reserved for VPN Gateway
# Must be named exactly "GatewaySubnet" — Azure requirement
resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Firewall subnet — reserved for Azure Firewall
# Must be named exactly "AzureFirewallSubnet" — Azure requirement
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Management subnet — bastion, admin tooling
resource "azurerm_subnet" "management" {
  name                 = "snet-management"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.3.0/24"]
}

# ─────────────────────────────────────────────
# SPOKE VIRTUAL NETWORK
# Workload network — AKS, data, migration tooling
# ─────────────────────────────────────────────

resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-${var.project}-spoke-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.spoke_vnet_cidr]
  tags                = var.tags
}

# AKS subnet — node pools live here
# /22 gives 1,022 usable IPs — pods consume IPs fast with Azure CNI
resource "azurerm_subnet" "aks" {
  name                 = "snet-aks"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = ["10.1.0.0/22"]
}

# Data subnet — private endpoints for ADLS and Azure SQL
resource "azurerm_subnet" "data" {
  name                 = "snet-data"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = ["10.1.4.0/24"]

  # Required for private endpoints
  private_endpoint_network_policies = "Disabled"
}

# Migration subnet — DMS replication instance
resource "azurerm_subnet" "migration" {
  name                 = "snet-migration"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = ["10.1.5.0/24"]
}

# ─────────────────────────────────────────────
# VNET PEERING
# Connects hub and spoke — traffic flows between them
# Non-transitive: spoke-to-spoke goes through hub
# ─────────────────────────────────────────────

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "peer-hub-to-spoke"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "peer-spoke-to-hub"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
  allow_forwarded_traffic   = true
  use_remote_gateways       = false
}

# ─────────────────────────────────────────────
# NETWORK SECURITY GROUPS
# Stateful firewalls — control traffic in and out of subnets
# Allow-only rules — deny everything not explicitly permitted
# ─────────────────────────────────────────────

# NSG for AKS subnet
resource "azurerm_network_security_group" "aks" {
  name                = "nsg-${var.project}-aks-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # Allow HTTPS inbound — application traffic
  security_rule {
    name                       = "allow-https-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow internal VNet traffic — pod-to-pod communication
  security_rule {
    name                       = "allow-vnet-inbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Deny all other inbound — explicit deny
  security_rule {
    name                       = "deny-all-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# NSG for data subnet — tighter rules, data protection
resource "azurerm_network_security_group" "data" {
  name                = "nsg-${var.project}-data-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # Allow only VNet traffic — no public access to data tier
  security_rule {
    name                       = "allow-vnet-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "deny-all-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# ─────────────────────────────────────────────
# NSG ASSOCIATIONS
# Attach NSGs to subnets — rules take effect
# ─────────────────────────────────────────────

resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

resource "azurerm_subnet_network_security_group_association" "data" {
  subnet_id                 = azurerm_subnet.data.id
  network_security_group_id = azurerm_network_security_group.data.id
}

