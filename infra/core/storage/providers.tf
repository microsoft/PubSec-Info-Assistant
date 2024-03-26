terraform {
  required_providers {
    azapi = {
      source = "azure/azapi"
      version = "~> 1.12.1"
    }
  }
}

provider "azapi" {
    use_cli = true
}
