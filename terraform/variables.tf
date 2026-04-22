variable "resource_group_name" {
  default = "openclaw-rg"
}

variable "location" {
  default = "East US"
}

variable "vm_size" {
  default = "Standard_B2s"
}

variable "admin_username" {
  default = "azureuser"
}

variable "ssh_public_key" {
  description = "Path to SSH public key"
}
