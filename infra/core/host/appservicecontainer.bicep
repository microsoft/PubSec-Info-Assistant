param appServiceName string
param appServicePlanName string
param containerRegistryName string
param location string = resourceGroup().location
param tags object = {}
param applicationInsightsName string = ''
param logAnalyticsWorkspaceName string = ''
param logAnalyticsWorkspaceResourceId string = !empty(logAnalyticsWorkspaceName) ? resourceId('Microsoft.OperationalInsights/workspaces', logAnalyticsWorkspaceName) : ''
param storageAccountUri string
param keyVaultName string = ''
param managedIdentity bool = !empty(keyVaultName)
param appSettings object = {}
param containerRegistrySuffix string = ''


// For simplicity, this uses the admin user for authenticating
// For production, consider other authentication options: https://docs.microsoft.com/en-us/azure/container-registry/container-registry-authentication
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-12-01' = {
  name: containerRegistryName
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

// Create an App Service Plan to group applications under the same payment plan and SKU, specifically for containers
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: 'P1v3'
    tier: 'PremiumV3'
    size: 'P1v3'
    family: 'Pv3'
    capacity: 3
  }
  kind: 'linux'
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 3
    isSpot: false
    reserved: true
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    zoneRedundant: false
  }
}


resource scaleOutRule 'Microsoft.Insights/autoscalesettings@2022-10-01' = {
  name: appServicePlan.name
  location: location
  properties: {
    enabled: true
    profiles: [
      {
        name: 'Scale out condition'
        capacity: {
          maximum: '3'
          default: '1'
          minimum: '1'
        }
        rules: [
          {
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
            metricTrigger: {
              metricName: 'ApproximateMessageCount'
              metricNamespace: ''
              metricResourceUri: storageAccountUri
              operator: 'GreaterThan'
              statistic: 'Average'
              threshold: 10
              timeAggregation: 'Average'
              timeGrain: 'PT1M'
              timeWindow: 'PT10M'
              dividePerInstance: true
            }
          }
        ]
      }
    ]
    targetResourceUri: appServicePlan.id
  }
}


resource appService 'Microsoft.Web/sites@2022-09-01' = {
name: appServiceName
location: location
tags: tags
// kind: 'app,linux,container'
kind: 'DOCKER'
identity: { type: managedIdentity ? 'SystemAssigned' : 'None' }
properties: {
  enabled: true
    serverFarmId: appServicePlan.id
    siteConfig: {
      numberOfWorkers: 1
      linuxFxVersion: 'DOCKER|mcr.microsoft.com/appsvc/staticsite:latest'
      acrUseManagedIdentityCreds: false
      alwaysOn: true
      http20Enabled: false
    }
    httpsOnly: true
  }
  resource configAppSettings 'config' = {
    name: 'appsettings'
    properties: union(appSettings,
      !empty(applicationInsightsName) ? { APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights.properties.ConnectionString } : {},
      { DOCKER_REGISTRY_SERVER_URL: 'https://${containerRegistry.name}.${containerRegistrySuffix}' }, 
      { DOCKER_REGISTRY_SERVER_USERNAME: containerRegistry.listCredentials().username },
      { DOCKER_REGISTRY_SERVER_PASSWORD: containerRegistry.listCredentials().passwords[0].value }
    )
  } 
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = if (!empty(applicationInsightsName)) {
  name: applicationInsightsName
}

resource diagnosticLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: appService.name
  scope: appService
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: [
      {
        category: 'AppServiceAppLogs'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: true 
        }
      }
      {
        category: 'AppServicePlatformLogs'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: true 
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: true 
        }
      }
    ]
  }
}

output appServiceName string = appService.name
output identityPrincipalId string = managedIdentity ? appService.identity.principalId : ''
output containerRegistryid string = containerRegistry.id
output containerRegistryName string = containerRegistry.name
output defaultDomain string = appService.properties.defaultHostName
