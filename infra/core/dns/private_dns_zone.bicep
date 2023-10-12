param privateDnsZoneName string
param apimName string
param vnetName string

resource parentAPIM 'Microsoft.ApiManagement/service@2023-03-01-preview' existing = {
  name: apimName
}

resource parentVnet 'Microsoft.ApiManagement/service@2023-03-01-preview' existing = {
  name: vnetName
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
  properties: {}
}

resource virtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: parentAPIM.name
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id:  resourceId('Microsoft.Network/VirtualNetworks', parentVnet.name)
    }
  }
  dependsOn: [
    parentVnet
    parentAPIM
  ]
}
