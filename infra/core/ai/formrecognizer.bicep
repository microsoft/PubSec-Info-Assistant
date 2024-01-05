param name string
param location string = resourceGroup().location
param tags object = {}
param keyVaultName string = ''

param customSubDomainName string = name
param publicNetworkAccess string = 'Enabled'
param isGovCloudDeployment bool  

param sku object = {
  name: 'S0'
}

// Form Recognizer 
resource formRecognizerAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = if (isGovCloudDeployment == false) {
  name: name
  location: location
  tags: tags
  kind: 'FormRecognizer'
  sku: sku
  properties: {
    customSubDomainName: customSubDomainName
    publicNetworkAccess: publicNetworkAccess
  }
}

// Form Recognizer Gov - Needed to support a lessor API.
resource formRecognizerAccountGov 'Microsoft.CognitiveServices/accounts@2022-12-01' = if (isGovCloudDeployment) {
  name: name
  location: location
  tags: tags
  kind: 'FormRecognizer'
  sku: sku
  properties: {
    customSubDomainName: customSubDomainName
    publicNetworkAccess: publicNetworkAccess
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = if (!(empty(keyVaultName))) {
  name: keyVaultName
}

resource formRecognizerKeySecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: keyVault
  name: 'AZURE-FORM-RECOGNIZER-KEY'
  properties: {
    value: (isGovCloudDeployment) ? formRecognizerAccountGov.listKeys().key1 : formRecognizerAccount.listKeys().key1
  }
}


output formRecognizerAccountName string = (isGovCloudDeployment) ? formRecognizerAccountGov.name : formRecognizerAccount.name
output formRecognizerAccountEndpoint string = (isGovCloudDeployment) ? formRecognizerAccountGov.properties.endpoint : formRecognizerAccount.properties.endpoint
