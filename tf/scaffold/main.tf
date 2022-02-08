provider "azurerm" {
  features {}
  alias           = "aks"
  subscription_id = var.AKS_SubscriptionId
}

provider "azurerm" {
  features {}
  alias           = "mgt"
  subscription_id = var.MGT_SubscriptionId
}

provider "azurerm" {
  features {}
  alias           = "acr"
  subscription_id = var.ACR_SubscriptionId
}

provider "azurerm" {
  features {}
  alias           = "hub"
  subscription_id = var.HUB_SubscriptionId
}


locals {
  module_tag = {
    "architecture_name"    = basename(abspath(path.module))
    "architecture_version" = "2022-01-25"
  }
  tags = merge(var.tags, local.module_tag)
}



data "azurerm_client_config" "current" {
  provider = azurerm.hub
}

# Generate randon name for virtual machine
resource "random_string" "guid" {
  length  = 8
  special = false
  lower   = true
  upper   = false
  number  = false
}


# ---------------------------------------------------------------------------------------------------------------------
# Configure Mgt
#
resource "azurerm_resource_group" "p_mgt_log" {
  name     = "p-mgt-log"
  provider = azurerm.mgt
  location = var.location
  tags     = local.tags
}

module "log_analytics_workspace" {
  source = "../modules/log_analytics"
  name   = "${azurerm_resource_group.p_mgt_log.name}-ws"
  providers = {
    azurerm = azurerm.mgt
  }
  location            = var.location
  tags                = local.tags
  resource_group_name = azurerm_resource_group.p_mgt_log.name
  solution_plan_map   = var.solution_plan_map
}


# ---------------------------------------------------------------------------------------------------------------------
# Configure Hub
#

resource "azurerm_resource_group" "p_hub_net" {
  name     = "p-we1hub-net"
  provider = azurerm.hub
  location = var.location
  tags     = local.tags
}


module "hub_network" {
  source              = "../modules/virtual_network"
  resource_group_name = azurerm_resource_group.p_hub_net.name
  providers = {
    azurerm = azurerm.hub
  }
  location                     = var.location
  vnet_name                    = "${azurerm_resource_group.p_hub_net.name}-vnet"
  address_space                = var.hub_address_space
  tags                         = local.tags
  log_analytics_workspace_id   = module.log_analytics_workspace.id
  log_analytics_retention_days = var.log_analytics_retention_days

  subnets = [
    {
      name : "GatewaySubnet"
      address_prefixes : var.hub_gateway_subnet_address_prefix
      enforce_private_link_endpoint_network_policies : true
      enforce_private_link_service_network_policies : false
    },
    {
      name : "AzureFirewallSubnet"
      address_prefixes : var.hub_firewall_subnet_address_prefix
      enforce_private_link_endpoint_network_policies : true
      enforce_private_link_service_network_policies : false
    },
    {
      name : "AzureBastionSubnet"
      address_prefixes : var.hub_bastion_subnet_address_prefix
      enforce_private_link_endpoint_network_policies : true
      enforce_private_link_service_network_policies : false
    }

  ]
}



module "firewall" {
  source = "../modules/firewall"
  name   = "${azurerm_resource_group.p_hub_net.name}-azfw"
  providers = {
    azurerm = azurerm.hub
  }
  resource_group_name = azurerm_resource_group.p_hub_net.name
  location            = var.location
  tags                = local.tags

  zones                        = ["1", "2", "3"]
  threat_intel_mode            = var.firewall_threat_intel_mode
  sku_tier                     = var.firewall_sku_tier
  pip_name                     = "${azurerm_resource_group.p_hub_net.name}-azfw-pip"
  subnet_id                    = module.hub_network.subnet_ids["AzureFirewallSubnet"]
  log_analytics_workspace_id   = module.log_analytics_workspace.id
  log_analytics_retention_days = var.log_analytics_retention_days
}


# ---------------------------------------------------------------------------------------------------------------------
# Configure AKS Spoke Networking
#

resource "azurerm_resource_group" "p_k8s_net" {
  name     = "p-we1k8s-net"
  provider = azurerm.aks
  location = var.location
  tags     = local.tags
}

module "aks_network" {
  source              = "../modules/virtual_network"
  resource_group_name = azurerm_resource_group.p_k8s_net.name
  providers = {
    azurerm = azurerm.aks
  }
  location                     = var.location
  vnet_name                    = "${azurerm_resource_group.p_k8s_net.name}-vnet"
  address_space                = var.aks_vnet_address_space
  tags                         = local.tags
  log_analytics_workspace_id   = module.log_analytics_workspace.id
  log_analytics_retention_days = var.log_analytics_retention_days

  subnets = [
    {
      name : "NodePoolSubnet"
      address_prefixes : var.aks_nodepool_subnet_address_prefix
      enforce_private_link_endpoint_network_policies : true
      enforce_private_link_service_network_policies : false
    },
    {
      name : "ResourceSubnet"
      address_prefixes : var.aks_resource_subnet_address_prefix
      enforce_private_link_endpoint_network_policies : true
      enforce_private_link_service_network_policies : false
    },
    {
      name : "AppGatewaySubnet"
      address_prefixes : var.aks_appgateway_subnet_address_prefix
      enforce_private_link_endpoint_network_policies : true
      enforce_private_link_service_network_policies : false
    },
    {
      name : "AzureBastionSubnet"
      address_prefixes : var.aks_bastion_subnet_address_prefix
      enforce_private_link_endpoint_network_policies : true
      enforce_private_link_service_network_policies : false
    }
  ]
}

module "vnet_peering" {
  source = "../modules/virtual_network_peering"
  providers = {
    azurerm = azurerm.aks
  }
  vnet_1_name         = module.hub_network.name
  vnet_1_id           = module.hub_network.id
  vnet_1_rg           = azurerm_resource_group.p_hub_net.name
  vnet_2_name         = module.aks_network.name
  vnet_2_id           = module.aks_network.id
  vnet_2_rg           = azurerm_resource_group.p_k8s_net.name
  peering_name_1_to_2 = "${module.hub_network.name}_To_${module.aks_network.name}"
  peering_name_2_to_1 = "${module.aks_network.name}_To_${module.hub_network.name}"
}

module "routetable" {
  source              = "../modules/route_table"
  resource_group_name = azurerm_resource_group.p_k8s_net.name
  providers = {
    azurerm = azurerm.aks
  }
  location            = var.location
  route_table_name    = "route-to-${azurerm_resource_group.p_hub_net.name}"
  route_name          = "next-hop-to-${azurerm_resource_group.p_hub_net.name}-azfw"
  firewall_private_ip = module.firewall.private_ip_address
  subnets_to_associate = {
    ("NodePoolSubnet") = {
      subnetId = module.aks_network.subnet_ids["NodePoolSubnet"]
      # subscription_id      = data.azurerm_client_config.current.subscription_id
      # resource_group_name  = azurerm_resource_group.rg.name
      # virtual_network_name = module.aks_network.name
    }
    ("ResourceSubnet") = {
      subnetId = module.aks_network.subnet_ids["ResourceSubnet"]
      # subscription_id      = data.azurerm_client_config.current.subscription_id
      # resource_group_name  = azurerm_resource_group.rg.name
      # virtual_network_name = module.aks_network.name
    }
  }
}

module "aks_bastion" {
  source              = "../modules/bastion_host"
  resource_group_name = azurerm_resource_group.p_k8s_net.name
  providers = {
    azurerm = azurerm.aks
  }
  location                     = var.location
  name                         = "${azurerm_resource_group.p_k8s_net.name}-bastion"
  subnet_id                    = module.aks_network.subnet_ids["AzureBastionSubnet"]
  log_analytics_workspace_id   = module.log_analytics_workspace.id
  log_analytics_retention_days = var.log_analytics_retention_days
}

# ---------------------------------------------------------------------------------------------------------------------
# Configure AKS Spoke Payload
#


resource "azurerm_resource_group" "p_k8s_aks" {
  name     = "p-we1k8s-aks"
  provider = azurerm.aks
  location = var.location
  tags     = local.tags
}


# ---------------------------------------------------------------------------------------------------------------------
# Configure AKS Spoke Jumpbox
#


resource "azurerm_resource_group" "p_k8s_jump" {
  name     = "p-we1k8s-jmp"
  provider = azurerm.aks
  location = var.location
  tags     = local.tags
}


module "storage_account" {
  source   = "../modules/storage_account"
  name     = "pwe1k8sjmp${random_string.guid.result}"
  location = var.location
  tags     = local.tags
  providers = {
    azurerm = azurerm.aks
  }
  resource_group_name = azurerm_resource_group.p_k8s_jump.name
  account_kind        = "StorageV2"
  account_tier        = "Standard"
  replication_type    = "LRS"
}

module "virtual_machine" {
  source              = "../modules/virtual_machine"
  name                = azurerm_resource_group.p_k8s_jump.name
  resource_group_name = azurerm_resource_group.p_k8s_jump.name
  providers = {
    azurerm = azurerm.aks
  }
  location = var.location
  tags     = local.tags
  size     = "Standard_DS1_v2"

  public_ip            = false
  vm_user              = "azureuser"
  admin_ssh_public_key = var.ssh_public_key
  os_disk_image = {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  domain_name_label                   = "var.domain_name"
  subnet_id                           = module.aks_network.subnet_ids["NodePoolSubnet"]
  os_disk_storage_account_type        = "Premium_LRS"
  boot_diagnostics_storage_account    = module.storage_account.primary_blob_endpoint
  log_analytics_workspace_id          = module.log_analytics_workspace.workspace_id
  log_analytics_workspace_key         = module.log_analytics_workspace.primary_shared_key
  log_analytics_workspace_resource_id = module.log_analytics_workspace.id
  log_analytics_retention_days        = var.log_analytics_retention_days
  # script_storage_account_name         = var.script_storage_account_name
  # script_storage_account_key          = var.script_storage_account_key
  # container_name                      = var.container_name
  # script_name                         = var.script_name
}

# ---------------------------------------------------------------------------------------------------------------------
# Configure ACR Spoke
#


resource "azurerm_resource_group" "p_k8s_acr" {
  name     = "p-we1k8s-acr"
  provider = azurerm.aks
  location = var.location
  tags     = local.tags
}

module "container_registry" {
  source              = "../modules/container_registry"
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.p_k8s_acr.name
  providers = {
    azurerm = azurerm.aks
  }
  location                     = var.location
  tags                         = local.tags
  sku                          = var.acr_sku
  admin_enabled                = var.acr_admin_enabled
  georeplication_locations     = var.acr_georeplication_locations
  log_analytics_workspace_id   = module.log_analytics_workspace.id
  log_analytics_retention_days = var.log_analytics_retention_days
}


# module "acr_private_dns_zone" {
#   source                       = "../modules/private_dns_zone"
#   name                         = "privatelink.azurecr.io"
#   resource_group_name          = azurerm_resource_group.p_k8s_acr.name
#   providers = {
#     azurerm = azurerm.aks
#   }
#   virtual_networks_to_link     = {
#     (module.hub_network.name) = {
#       subscription_id = data.azurerm_client_config.current.subscription_id
#       resource_group_name = azurerm_resource_group.rg.name
#     }
#     (module.aks_network.name) = {
#       subscription_id = data.azurerm_client_config.current.subscription_id
#       resource_group_name = azurerm_resource_group.rg.name
#     }
#   }
# }

# module "acr_private_endpoint" {
#   source                         = "../modules/private_endpoint"
#   name                           = "${module.container_registry.name}PrivateEndpoint"
#   location                       = var.location
#   resource_group_name            = azurerm_resource_group.p_k8s_acr.name
#   subnet_id                      = module.aks_network.subnet_ids[var.vm_subnet_name]
#   tags                           = local.tags
#   private_connection_resource_id = module.container_registry.id
#   is_manual_connection           = false
#   subresource_name               = "registry"
#   private_dns_zone_group_name    = "AcrPrivateDnsZoneGroup"
#   private_dns_zone_group_ids     = [module.acr_private_dns_zone.id]
# }
