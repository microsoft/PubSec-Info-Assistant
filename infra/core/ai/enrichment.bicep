param name string
param location string = resourceGroup().location
param tags object = {}
param sku string = ''

resource cognitiveService 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: 'CognitiveServices'
  properties: {
    apiProperties: {
      statisticsEnabled: false
    }
  }
}


output cognitiveServicerAccountName string = cognitiveService.name
output cognitiveServiceID string = cognitiveService.id
output cognitiveServiceEndpoint string = cognitiveService.properties.endpoint
#disable-next-line outputs-should-not-contain-secrets
output cognitiveServiceAccountKey string = cognitiveService.listKeys().key1
