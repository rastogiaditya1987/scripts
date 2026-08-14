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
  storage_account_name = "adistoragesa"
  container_name       = "adi-container"
  key                  = "terraform.tfstate"
  use_oidc             = true

use_azuread_auth = true
subscription_id  = "a587b56f-da71-4e67-b31f-8b03bc7e50ac"
tenant_id        = "32c37a62-9306-4b6e-8c4c-ec2e9bcdc260"
  }
}

provider "azurerm" {
  features {}
}
