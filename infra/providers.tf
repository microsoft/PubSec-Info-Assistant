terraform {
  required_version = ">= 0.15.3"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.93.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.47.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0.0"
    }
    azapi = {
      source = "azure/azapi"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
  environment = var.azure_environment == "AzureUSGovernment" ? "usgovernment" : "public"
}

provider "azuread" {
  environment = var.azure_environment == "AzureUSGovernment" ? "usgovernment" : "public"
}

provider "azapi" {
}
