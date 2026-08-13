terraform {
  required_version = "~> 1.15.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.116.0, < 5.0.0"
    }

    azapi = {
      source  = "azure/azapi"
      version = ">= 2.4.0"
    }

    modtm = {
      source  = "azure/modtm"
      version = "~> 0.3"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "Aditya-RG"
    storage_account_name = "saadityastorage001"
    container_name       = "tfstate-adi"
    key                  = "avm.tfstate"
    use_oidc             = true
  }
}

provider "azurerm" {
  features {}
}
