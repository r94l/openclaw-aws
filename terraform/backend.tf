terraform {
  backend "azurerm" {
    resource_group_name  = "NetworkWatcherRG"
    storage_account_name = "openclawkr"
    container_name       = "openclaw-kr"
    key                  = "terraform.tfstate"
  }
}
