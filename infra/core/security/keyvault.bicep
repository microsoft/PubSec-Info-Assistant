param name string
param location string = resourceGroup().location
param kvAccessObjectId string 
@secure()
param openaiServiceKey string
@secure()
param spClientSecret string 



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

resource openaiServiceKeySecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: kv
  name: 'AZURE-OPENAI-SERVICE-KEY'
  properties: {
    value: openaiServiceKey 
  }
}

resource spClientKeySecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: kv
  name: 'AZURE-CLIENT-SECRET'
  properties: {
    value: spClientSecret 
  }
}

output keyVaultName string = kv.name
output keyVaultUri string = kv.properties.vaultUri
