param name string
param cogServicesName string
param location string = resourceGroup().location
param tags object = {}

param sku object = {
  name: 'standard'
}

param authOptions object = {}
param semanticSearch string = 'disabled'
param kind string = 'CognitiveServices'
param publicNetworkAccess string = 'Enabled'
param cogServicesSku object = {
  name: 'S0'
}

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
    semanticSearch: semanticSearch
  }
  sku: sku
}

resource cogService 'Microsoft.CognitiveServices/accounts@2022-10-01' = {
  name: cogServicesName
  location: location
  tags: tags
  kind: kind
  properties: {
    publicNetworkAccess: publicNetworkAccess
  }
  sku: cogServicesSku
}

output id string = search.id
output endpoint string = 'https://${name}.search.windows.net/'
output name string = search.name
#disable-next-line outputs-should-not-contain-secrets 
output cogServiceKey string = cogService.listKeys().key1
