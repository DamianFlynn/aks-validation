variable "ACR_SubscriptionId" {
  description = "SubscriptionId for the ACR Landing Zone"
  default     = "283dd4da-759e-4ceb-a6ef-618ebebb7705"
}

variable "MGT_SubscriptionId" {
  description = "SubscriptionId for the ACR Landing Zone"
  default     = "283dd4da-759e-4ceb-a6ef-618ebebb7705"
}

variable "AKS_SubscriptionId" {
  description = "SubscriptionId for the ACR Landing Zone"
  default     = "283dd4da-759e-4ceb-a6ef-618ebebb7705"
}

variable "HUB_SubscriptionId" {
  description = "SubscriptionId for the HUB Landing Zone"
  default     = "283dd4da-759e-4ceb-a6ef-618ebebb7705"
}



## HUB Landing Zone Network Settings

variable "hub_address_space" {
  description = "Specifies the address prefix of the Hub vNET"
  type        = list(string)
  default = ["10.182.0.0/22"]
}

variable "hub_firewall_subnet_address_prefix" {
  description = "Hub AzFirewall Subnet address space"
  type        = list(string)
  default = ["10.182.1.0/24"]
}

variable "hub_gateway_subnet_address_prefix" {
  description = "Hub Gateway Subnet address space"
  type        = list(string)
  default = ["10.182.0.0/24"]
}

variable "hub_bastion_subnet_address_prefix" {
  description = "HUB Azure Bastion Subnet address space"
  type        = list(string)
  default = ["10.182.3.0/24"]
}

## Firewall

variable "firewall_sku_tier" {
  description = "Specifies the SKU tier of the Azure Firewall"
  default     = "Standard"
  type        = string
}

variable "firewall_threat_intel_mode" {
  description = "(Optional) The operation mode for threat intelligence-based filtering. Possible values are: Off, Alert, Deny. Defaults to Alert."
  default     = "Alert"
  type        = string

  validation {
    condition = contains(["Off", "Alert", "Deny"], var.firewall_threat_intel_mode)
    error_message = "The threat intel mode is invalid."
  }
}

## AKS Landing Zone Network Settings

variable "aks_vnet_address_space" {
  description = "Specifies the address prefix of the AKS subnet"
  type        = list(string)
  default = ["10.182.16.0/22"]
}

variable "aks_nodepool_subnet_address_prefix" {
  description = "NodePool Subnet address space"
  type        = list(string)
  default = ["10.182.16.0/23"]
}

variable "aks_resource_subnet_address_prefix" {
  description = "Resources Subnet address space"
  type        = list(string)
  default = ["10.182.18.0/24"]
}

variable "aks_appgateway_subnet_address_prefix" {
  description = "appGateway Subnet address space"
  type        = list(string)
  default = ["10.182.19.0/25"]
}

variable "aks_bastion_subnet_address_prefix" {
  description = "HUB Azure Bastion Subnet address space"
  type        = list(string)
  default = ["10.182.19.128/26"] 
}

## ACR Landing Zone Network Settings

variable "acr_sku" {
  description = "Specifies the name of the container registry"
  type        = string
  default     = "Standard"

  validation {
    condition = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "The container registry sku is invalid."
  }
}