param name string
param location string = resourceGroup().location
param tags object = {}
param keyVaultName string = ''


@description('The default consistency level of the Cosmos DB account.')
@allowed([
  'Eventual'
  'ConsistentPrefix'
  'Session'
  'BoundedStaleness'
  'Strong'
])
param defaultConsistencyLevel string = 'Session'

@description('Max stale requests. Required for BoundedStaleness. Valid ranges, Single Region: 10 to 2147483647. Multi Region: 100000 to 2147483647.')
@minValue(10)
@maxValue(2147483647)
param maxStalenessPrefix int = 100000


@description('Max lag time (minutes). Required for BoundedStaleness. Valid ranges, Single Region: 5 to 84600. Multi Region: 300 to 86400.')
@minValue(5)
@maxValue(86400)
param maxIntervalInSeconds int = 300

@description('Enable system managed failover for regions')
param systemManagedFailover bool = true


@description('The name for the log database')
param logDatabaseName string

@description('The name for the log container')
param logContainerName string

@description('Maximum autoscale throughput for the container')
@minValue(1000)
@maxValue(1000000)
param autoscaleMaxThroughput int = 1000

var consistencyPolicy = {
  Eventual: {
    defaultConsistencyLevel: 'Eventual'
  }
  ConsistentPrefix: {
    defaultConsistencyLevel: 'ConsistentPrefix'
  }
  Session: {
    defaultConsistencyLevel: 'Session'
  }
  BoundedStaleness: {
    defaultConsistencyLevel: 'BoundedStaleness'
    maxStalenessPrefix: maxStalenessPrefix
    maxIntervalInSeconds: maxIntervalInSeconds
  }
  Strong: {
    defaultConsistencyLevel: 'Strong'
  }
}
var locations = [
  {
    locationName: location
    failoverPriority: 0
    isZoneRedundant: false
  }
]


resource cosmosDBAccount 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' = {
  name: toLower(name)
  kind: 'GlobalDocumentDB'
  location: location
  tags: tags
  properties: {
    consistencyPolicy: consistencyPolicy[defaultConsistencyLevel]
    locations: locations
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: systemManagedFailover
  }
}

resource logDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2022-05-15' = {
  parent: cosmosDBAccount
  name: logDatabaseName
  properties: {
    resource: {
      id: logDatabaseName
    }
  }
}

resource logContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-05-15' = {
  parent: logDatabase
  name: logContainerName
  properties: {
    resource: {
      id: logContainerName
      partitionKey: {
        paths: [
          '/file_name'
        ]
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
      }
    }
    options: {
      autoscaleSettings: {
        maxThroughput: autoscaleMaxThroughput
      }
    }
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = if (!(empty(keyVaultName))) {
  name: keyVaultName
}

resource cosmosdbKeySecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: keyVault
  name: 'COSMOSDB-KEY'
  properties: {
    value: cosmosDBAccount.listKeys().primaryMasterKey 
  }
}

output CosmosDBEndpointURL string = cosmosDBAccount.properties.documentEndpoint
output CosmosDBLogDatabaseName string = logDatabase.name
output CosmosDBLogContainerName string = logContainer.name
