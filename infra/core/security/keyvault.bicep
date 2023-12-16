param name string
param location string = resourceGroup().location
param kvAccessObjectId string 
@secure()
param searchServiceKey string
@secure()
param openaiServiceKey string
@secure()
param cosmosdbKey string
@secure()
param formRecognizerKey string
@secure()
param blobConnectionString string
@secure()
param enrichmentKey string
@secure()
param spClientSecret string
@secure()
param blobStorageKey string 



resource kv 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: name
  location: location
  
  properties: {
    enabledForTemplateDeployment: true
    createMode: 'default'
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: kvAccessObjectId 
        permissions: {
          keys: ['all']
          secrets: ['all']
        }
      }
    ]
  }
}

resource searchServiceKeySecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: kv
  name: 'AZURE-SEARCH-SERVICE-KEY'
  properties: {
    value: searchServiceKey 
    attributes: {
      enabled: true
    }
  }
}

resource openaiServiceKeySecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: kv
  name: 'AZURE-OPENAI-SERVICE-KEY'
  properties: {
    value: openaiServiceKey 
  }
}

resource cosmosdbKeySecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: kv
  name: 'COSMOSDB-KEY'
  properties: {
    value: cosmosdbKey 
  }
}

resource formRecognizerKeySecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: kv
  name: 'AZURE-FORM-RECOGNIZER-KEY'
  properties: {
    value: formRecognizerKey 
  }
}

resource blobConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: kv
  name: 'BLOB-CONNECTION-STRING'
  properties: {
    value: blobConnectionString 
  }
}

resource enrichmentKeySecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: kv
  name: 'ENRICHMENT-KEY'
  properties: {
    value: enrichmentKey 
  }
}

resource spClientKeySecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: kv
  name: 'AZURE-CLIENT-SECRET'
  properties: {
    value: spClientSecret 
  }
}

resource blobStorageKeySecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: kv
  name: 'AZURE-BLOB-STORAGE-KEY'
  properties: {
    value: blobStorageKey 
  }
}

output keyVaultName string = kv.name
