terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Uncomment to use remote state (recommended for real deployments)
  # backend "azurerm" {
  #   resource_group_name  = "tfstate-rg"
  #   storage_account_name = "tfstateXXXXXX"
  #   container_name       = "tfstate"
  #   key                  = "openclaw.tfstate"
  # }
}

provider "azurerm" {
  features {
    virtual_machine {
      # Ensures OS disk is deleted when VM is destroyed
      delete_os_disk_on_deletion = true
    }
  }
}

# ──────────────────────────────────────────────
# Resource Group
# ──────────────────────────────────────────────
resource "azurerm_resource_group" "openclaw" {
  name     = "${var.prefix}-rg"
  location = var.location

  tags = local.common_tags
}

# ──────────────────────────────────────────────
# Networking
# ──────────────────────────────────────────────
resource "azurerm_virtual_network" "openclaw" {
  name                = "${var.prefix}-vnet"
  resource_group_name = azurerm_resource_group.openclaw.name
  location            = azurerm_resource_group.openclaw.location
  address_space       = ["10.0.0.0/16"]

  tags = local.common_tags
}

resource "azurerm_subnet" "openclaw" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.openclaw.name
  virtual_network_name = azurerm_virtual_network.openclaw.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "openclaw" {
  name                = "${var.prefix}-pip"
  resource_group_name = azurerm_resource_group.openclaw.name
  location            = azurerm_resource_group.openclaw.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
}

# ──────────────────────────────────────────────
# Network Security Group
# Only port 2222 (SSH) is opened publicly.
# Port 22 is intentionally never opened.
# Once Tailscale is confirmed working, remove
# the ssh_inbound rule and apply again to go
# fully dark (zero public ports).
# ──────────────────────────────────────────────
resource "azurerm_network_security_group" "openclaw" {
  name                = "${var.prefix}-nsg"
  resource_group_name = azurerm_resource_group.openclaw.name
  location            = azurerm_resource_group.openclaw.location

  # SSH on non-standard port — restrict to your IP
  security_rule {
    name                       = "ssh_inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.ssh_port)
    source_address_prefix      = var.allowed_ssh_cidr
    destination_address_prefix = "*"
  }

  # Deny everything else inbound (explicit default)
  security_rule {
    name                       = "deny_all_inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

resource "azurerm_subnet_network_security_group_association" "openclaw" {
  subnet_id                 = azurerm_subnet.openclaw.id
  network_security_group_id = azurerm_network_security_group.openclaw.id
}

# ──────────────────────────────────────────────
# SSH Key Pair
# Terraform generates the key; private key is
# saved locally as openclaw.pem
# ──────────────────────────────────────────────
resource "tls_private_key" "openclaw" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.openclaw.private_key_pem
  filename        = "${path.module}/openclaw.pem"
  file_permission = "0600"
}

# ──────────────────────────────────────────────
# Network Interface
# ──────────────────────────────────────────────
resource "azurerm_network_interface" "openclaw" {
  name                = "${var.prefix}-nic"
  resource_group_name = azurerm_resource_group.openclaw.name
  location            = azurerm_resource_group.openclaw.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.openclaw.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.openclaw.id
  }

  tags = local.common_tags
}

resource "azurerm_network_interface_security_group_association" "openclaw" {
  network_interface_id      = azurerm_network_interface.openclaw.id
  network_security_group_id = azurerm_network_security_group.openclaw.id
}

# ──────────────────────────────────────────────
# Virtual Machine
# ──────────────────────────────────────────────
resource "azurerm_linux_virtual_machine" "openclaw" {
  name                  = "${var.prefix}-vm"
  resource_group_name   = azurerm_resource_group.openclaw.name
  location              = azurerm_resource_group.openclaw.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.openclaw.id]

  # cloud-init runs at first boot — full setup, zero manual steps
  custom_data = base64encode(templatefile("${path.module}/scripts/cloud-init.yaml", {
    ssh_port          = var.ssh_port
    admin_username    = var.admin_username
    tailscale_authkey = var.tailscale_authkey
    openclaw_version  = var.openclaw_version
  }))

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.openclaw.public_key_openssh
  }

  os_disk {
    name                 = "${var.prefix}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Disable password authentication — key only
  disable_password_authentication = true

  tags = local.common_tags
}

# ──────────────────────────────────────────────
# Locals
# ──────────────────────────────────────────────
locals {
  common_tags = {
    project     = "openclaw"
    environment = var.environment
    managed_by  = "terraform"
  }
}
