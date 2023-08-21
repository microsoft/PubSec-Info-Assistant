@description('Name of the avam')
param name string

@description('Location of the service')
param location string = resourceGroup().location

@description('Tags for the service')
param tags object = {}

@description('ID of the storage account used by avam')
param storageAccountID string 


resource avam 'Microsoft.Media/mediaservices@2023-01-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  } 
  properties: {
    publicNetworkAccess: 'Disabled'
    storageAccounts: [
      {
        id: storageAccountID
        identity: {
          useSystemAssignedIdentity: true
        }
        type: 'Primary'
      }
    ]
  }
}

output id string = avam.id
