param name string
param location string = resourceGroup().location
param tags object = {}

param sku object = {
  name: 'standard'
}

param authOptions object = {}
param semanticSearch string = 'disabled'
param isGovCloudDeployment bool  
param keyVaultName string = ''

resource search 'Microsoft.Search/searchServices@2021-04-01-preview' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    authOptions: authOptions
    disableLocalAuth: false
    disabledDataExfiltrationOptions: []
    encryptionWithCmk: {
      enforcement: 'Unspecified'
    }
    hostingMode: 'default'
    networkRuleSet: {
      bypass: 'None'
      ipRules: []
    }
    partitionCount: 1
    publicNetworkAccess: 'Enabled'
    replicaCount: 1
    semanticSearch:  ((isGovCloudDeployment) ? null : semanticSearch)
  }
  sku: sku
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = if (!(empty(keyVaultName))) {
  name: keyVaultName
}

resource searchServiceKeySecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: keyVault
  name: 'AZURE-SEARCH-SERVICE-KEY'
  properties: {
    value: search.listAdminKeys().primaryKey 
    attributes: {
      enabled: true
    }
  }
}


output id string = search.id
output endpoint string = (isGovCloudDeployment) ? 'https://${name}.search.azure.us/' : 'https://${name}.search.windows.net/'
output name string = search.name
