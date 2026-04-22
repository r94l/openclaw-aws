variable "resource_group_name" {
  default = "openclaw-rg"
}

variable "location" {
  default = "westeurope"
}

variable "vm_size" {
  default = "Standard_B2s_v2"
}

variable "admin_username" {
  default = "azureuser"
}

variable "ssh_public_key" {
  description = "Path to SSH public key"
}
