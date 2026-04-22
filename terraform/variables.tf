variable "resource_group_name" {
  default = "openclaw-rg"
}

variable "location" {
  default = "westeurope"
}

variable "vm_size" {
  default = "Standard_D2s_v3"
}

variable "admin_username" {
  default = "azureuser"
}

variable "ssh_public_key" {
  description = "Path to SSH public key"
}
