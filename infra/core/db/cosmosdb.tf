

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

resource "azurerm_monitor_diagnostic_setting" "diagnostic_setting" {
  name                       = lower(var.name)
  target_resource_id         = azurerm_cosmosdb_account.cosmosdb_account.id
  log_analytics_workspace_id = var.logAnalyticsWorkspaceResourceId

  enabled_log {
    category = "DataPlaneRequests"
  }
  enabled_log {
    category = "MongoRequests"
  }
  enabled_log {
    category = "QueryRuntimeStatistics"
  }
  enabled_log {
    category = "PartitionKeyStatistics"
  }
  enabled_log {
    category = "PartitionKeyRUConsumption"
  }
  enabled_log {
    category = "ControlPlaneRequests"
  }
  enabled_log {
    category = "CassandraRequests"
  }
  enabled_log {
    category = "GremlinRequests"
  }
  enabled_log {
    category = "TableApiRequests"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
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

resource "azurerm_key_vault_secret" "cosmos_db_key" {
  name         = "COSMOSDB-KEY"
  value        = azurerm_cosmosdb_account.cosmosdb_account.primary_key
  key_vault_id = var.keyVaultId
}

output "CosmosDBEndpointURL" {
  value = azurerm_cosmosdb_account.cosmosdb_account.endpoint
}

output "CosmosDBLogDatabaseName" {
  value = azurerm_cosmosdb_sql_database.log_database.name
}

output "CosmosDBLogContainerName" {
  value = azurerm_cosmosdb_sql_container.log_container.name
}