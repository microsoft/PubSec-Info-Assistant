@description('The location into which the API Management resources should be deployed.')
param location string

@description('The name of the API Management service instance to create. This must be globally unique.')
param serviceName string

@description('The name of the API publisher. This information is used by API Management.')
param publisherName string

@description('The email address of the API publisher. This information is used by API Management.')
param publisherEmail string

@description('The name of the SKU to use when creating the API Management service instance. This must be a SKU that supports virtual network integration.')
@allowed([
  'Developer'
  'Premium'
])
param skuName string

@description('The number of worker instances of your API Management service that should be provisioned.')
param skuCount int

param virtualNetworkType string

param subnetResourceId string

param apiManagementNamedValueName string

param azureOpenAiKey string

resource apiManagementServiceVnetIntegration 'Microsoft.ApiManagement/service@2023-03-01-preview' = {
  name: serviceName
  location: location
  sku: {
    name: skuName
    capacity: skuCount
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherName: publisherName
    publisherEmail: publisherEmail
    virtualNetworkConfiguration: {
      subnetResourceId: subnetResourceId
    }
    virtualNetworkType: virtualNetworkType
  }
}

resource apiManagementService 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: serviceName

  resource namedValue 'namedValues' = {
    name: apiManagementNamedValueName
    dependsOn: [
      apiManagementServiceVnetIntegration
    ]
    properties: {
      displayName: apiManagementNamedValueName
      value: azureOpenAiKey
      secret: true
    }
  }
}

output apiManagementInternalIPAddress string = apiManagementServiceVnetIntegration.properties.publicIPAddresses[0]
output apiManagementIdentityPrincipalId string = apiManagementServiceVnetIntegration.identity.principalId
output apiManagementProxyHostName string = apiManagementServiceVnetIntegration.properties.hostnameConfigurations[0].hostName
output apiManagementDeveloperPortalHostName string = replace(apiManagementServiceVnetIntegration.properties.developerPortalUrl, 'https://', '')

