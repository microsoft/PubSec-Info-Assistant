param name string
param location string = resourceGroup().location
param tags object = {}

param customSubDomainName string = name
param publicNetworkAccess string = 'Enabled'
param sku object = {
  name: 'S0'
}

// Form Recognizer
resource formRecognizerAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
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

output formRecognizerAccountName string = formRecognizerAccount.name
output formRecognizerAccountEndpoint string = formRecognizerAccount.properties.endpoint
#disable-next-line outputs-should-not-contain-secrets
output formRecognizerAccountKey string = formRecognizerAccount.listKeys().key1
