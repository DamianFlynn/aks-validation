# Configure Terraform to set the required provider version

terraform {
  required_version = ">= 1.1.3"
  
  backend "azurerm" {
  }
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.91.0"
    }

#    kubectl = {
#      source  = "gavinbunney/kubectl"
#      version = ">= 1.13.0"
#    }
  }
}
