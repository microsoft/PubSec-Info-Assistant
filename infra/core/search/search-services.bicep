param name string
param location string = resourceGroup().location
param tags object = {}

param sku object = {
  name: 'standard'
}

param authOptions object = {}
param semanticSearch string = 'disabled'
param isGovCloudDeployment bool  

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


output id string = search.id
output endpoint string = (isGovCloudDeployment) ? 'https://${name}.search.azure.us/' : 'https://${name}.search.windows.net/'
output name string = search.name
#disable-next-line outputs-should-not-contain-secrets
output searchServiceKey string = search.listAdminKeys().primaryKey
