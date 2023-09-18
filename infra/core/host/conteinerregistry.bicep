@description('Name of the service')
param name string

@description('Location of the service')
param location string = resourceGroup().location

@description('Tags for the service')
param tags object = {}


// For simplicity, this uses the admin user for authenticating
// For production, consider other authentication options: https://docs.microsoft.com/en-us/azure/container-registry/container-registry-authentication
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-12-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  } 
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}


output id string = containerRegistry.id
output name string = containerRegistry.name
output username string = containerRegistry.listCredentials().username
output password string = containerRegistry.listCredentials().passwords[0].value
