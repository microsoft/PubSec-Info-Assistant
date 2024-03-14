

locals {
  consistencyPolicy = {
    Eventual = {
      defaultConsistencyLevel = "Eventual"
    }
    ConsistentPrefix = {
      defaultConsistencyLevel = "ConsistentPrefix"
    }
    Session = {
      defaultConsistencyLevel = "Session"
    }
    BoundedStaleness = {
      defaultConsistencyLevel = "BoundedStaleness"
      maxStalenessPrefix      = var.maxStalenessPrefix
      maxIntervalInSeconds    = var.maxIntervalInSeconds
    }
    Strong = {
      defaultConsistencyLevel = "Strong"
    }
  }
  locations = [
    {
      locationName     = var.location
      failoverPriority = 0
      isZoneRedundant  = false
    }
  ]
}



resource "azurerm_cosmosdb_account" "cosmosdb_account" {
  name                = lower(var.name)
  location            = var.location
  resource_group_name = var.resourceGroupName
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level       = var.defaultConsistencyLevel
    max_interval_in_seconds = var.maxIntervalInSeconds
    max_staleness_prefix    = var.maxStalenessPrefix
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  tags = var.tags
}

resource "azurerm_cosmosdb_sql_database" "log_database" {
  name                = var.logDatabaseName
  resource_group_name = var.resourceGroupName
  account_name        = azurerm_cosmosdb_account.cosmosdb_account.name
}

resource "azurerm_cosmosdb_sql_container" "log_container" {
  name                = var.logContainerName
  resource_group_name = var.resourceGroupName
  account_name        = azurerm_cosmosdb_account.cosmosdb_account.name
  database_name       = azurerm_cosmosdb_sql_database.log_database.name

  partition_key_path = "/file_name"

  autoscale_settings {
    max_throughput = var.autoscaleMaxThroughput
  }
}

resource "azurerm_cosmosdb_sql_database" "tag_database" {
  name                = var.tagDatabaseName
  resource_group_name = var.resourceGroupName
  account_name        = azurerm_cosmosdb_account.cosmosdb_account.name
}

resource "azurerm_cosmosdb_sql_container" "tag_container" {
  name                = var.tagContainerName
  resource_group_name = var.resourceGroupName
  account_name        = azurerm_cosmosdb_account.cosmosdb_account.name
  database_name       = azurerm_cosmosdb_sql_database.tag_database.name

  partition_key_path = "/file_path"

  autoscale_settings {
    max_throughput = var.autoscaleMaxThroughput
  }
}

resource "azurerm_key_vault_secret" "search_service_key" {
  name         = "COSMOSDB-KEY"
  value        = azurerm_cosmosdb_account.cosmosdb_account.primary_key
  key_vault_id = var.keyVaultId
}

resource "azurerm_private_endpoint" "private_endpoint" {
  name                          = "${var.name}-private-endpoint"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  subnet_id                     = var.subnet_id
  custom_network_interface_name = "'${var.name}-network-interface'"

  private_service_connection {
    name                           = "${var.name}-private-link-service-connection"
    private_connection_resource_id = azurerm_cosmosdb_account.cosmosdb_account.id
    is_manual_connection           = false

  }
}

resource "azurerm_private_dns_zone" "cosmosdbDnsZone" {
  name                = "${var.name}-private-dns-zone-group"
  resource_group_name = var.resourceGroupName

}


