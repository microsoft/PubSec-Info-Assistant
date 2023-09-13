@description('Name of the video indexer service')
param name string

@description('Location of the service')
param location string = resourceGroup().location

@description('Tags for the service')
param tags object = {}

@description('ID of the Azure media service')
param mediaServiceAccountResourceId string


resource avam 'Microsoft.VideoIndexer/accounts@2022-08-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    mediaServices: {
      resourceId: mediaServiceAccountResourceId
    }
  }
}
