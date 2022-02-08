variable "location" {
  default = "westeurope"
}


variable "tags" {
  description = "(Optional) Specifies tags for all the resources"
  default     = {
    createdWith = "Terraform"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Configure Logs 
#


variable "log_analytics_retention_days" {
  description = "Specifies the number of days of the retention policy"
  type        = number
  default     = 365
}

variable "solution_plan_map" {
  description = "Specifies solutions to deploy to log analytics workspace"
  default     = {
    ContainerInsights= {
      product   = "OMSGallery/ContainerInsights"
      publisher = "Microsoft"
    }
    KeyVaultAnalytics= {
      product = "OMSGallery/KeyVaultAnalytics"
      publisher = "Microsoft"
    }
  }
  type = map(any)
}


# ---------------------------------------------------------------------------------------------------------------------
# Configure ACR 
#

variable "acr_name" {
  description = "Specifies the name of the container registry"
  type        = string
  default     = "WalWilReg"
}



variable "acr_admin_enabled" {
  description = "Specifies whether admin is enabled for the container registry"
  type        = bool
  default     = true
}

variable "acr_georeplication_locations" {
  description = "(Optional) A list of Azure locations where the container registry should be geo-replicated."
  type        = list(string)
  default     = []
}



variable "ssh_public_key" {
  description = "(Required) Specifies the SSH public key for the jumpbox virtual machine and AKS worker nodes."
  type        = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDpTPg902uyF9QmsTxvFwNpWaIQhrm8nWE3H1sumL0MXOP2fa8Ld+d8fJUunHHyXFLqxUuGYeYTcQTt5Uez5iRTF88zngbltgHr7LABBVwZQR0MVZUL4lLqLrx4b0HJFThf4NaAk7ZpQt70Qe/3ljBt55Tzhiz3py2Tr2vx0JIqsRR91t4NUHztqCWl5ZzGc2hb7ZEz80y+F4emYfWBBDY2HjgMWBIk8ZEsiW58Nf5akmCDYBdAE5XPaCZVnMOaiXM+jQH62JzRlmBDQ0yDPcVU05qqz0XKOotY1RZfwx8jztuBVp5CUOF4sKhJtInZnHuQSGIWPJZqSjLmhGrtXCOI+U/LmKS3fb00EIpM6PWWQwJcy8fLP3DaNR7FjRCFEfGxYu/pQczq7ihUXwJ5kVZaEB62dgs7oSIi5kgt+YxXAv3jjoauBG/DHgrZTmuf4TscLHsjA+p2Koux+8WdbjbYUy5OdDlCjggQLzal/70o/OLs/EPDxECi2c88RwUDPH7/KtVqJ46QHB5xuN0MgWO1h4kLilOkZ1B1YyPjDufKW96b27PjkFMmV1dq5wM+ybvL2kTNONL5svZUpQWAhtQMNy0DSnmbCM5jCzN60kiDg5CQzYNZSjeXZiamTsMMfzUmPcMSz0PfOAgmgYEdVWBKCIQVDsH9ua7oiP+MpdzxzQ== root@172.16.1.70"
}

variable "domain_name" {
  description = "(Required) Specifies the SSH public key for the jumpbox virtual machine and AKS worker nodes."
  type        = string
  default = "p3.walwil.com"
}