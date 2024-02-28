output "CosmosDBEndpointURL" {
  value = azurerm_cosmosdb_account.cosmosdb_account.endpoint
}

output "CosmosDBLogDatabaseName" {
  value = azurerm_cosmosdb_sql_database.log_database.name
}

output "CosmosDBLogContainerName" {
  value = azurerm_cosmosdb_sql_container.log_container.name
}

output "CosmosDBTagsDatabaseName" {
  value = azurerm_cosmosdb_sql_database.tag_database.name
}

output "CosmosDBTagsContainerName" {
  value = azurerm_cosmosdb_sql_container.tag_container.name
}