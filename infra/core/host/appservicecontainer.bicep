param appServiceName string
param appServicePlanName string
param location string = resourceGroup().location
param tags object = {}
param applicationInsightsName string = ''
param logAnalyticsWorkspaceName string = ''
param logAnalyticsWorkspaceResourceId string = !empty(logAnalyticsWorkspaceName) ? resourceId('Microsoft.OperationalInsights/workspaces', logAnalyticsWorkspaceName) : ''

param appSettings object = {}

// Create an App Service Plan to group applications under the same payment plan and SKU, specifically for containers
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: 'S1'
    tier: 'Standard'
    size: 'S1'
    family: 'S'
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

resource appService 'Microsoft.Web/sites@2022-09-01' = {
name: appServiceName
location: location
tags: tags
kind: 'app,linux,container'
identity: {
  type: 'SystemAssigned'
}
properties: {
  enabled: true
    hostNameSslStates: [
      {
        name: '${appServiceName}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${appServiceName}.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
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
      !empty(applicationInsightsName) ? { APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights.properties.ConnectionString } : {}
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

output name string = appService.name
