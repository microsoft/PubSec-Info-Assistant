param name string
param location string = resourceGroup().location
param tags object = {}

// Reference Properties
param applicationInsightsName string = ''
param logAnalyticsWorkspaceName string = ''
param appServicePlanId string
param keyVaultName string = ''
param managedIdentity bool = !empty(keyVaultName)

// Runtime Properties
@allowed([
  'dotnet', 'dotnetcore', 'dotnet-isolated', 'node', 'python', 'java', 'powershell', 'custom'
])
param runtimeName string
param runtimeNameAndVersion string = '${runtimeName}|${runtimeVersion}'
param runtimeVersion string

// Microsoft.Web/sites Properties
param kind string = 'app,linux'

// Microsoft.Web/sites/config
param allowedOrigins array = []
param alwaysOn bool = true
param appCommandLine string = ''
param appSettings object = {}
param clientAffinityEnabled bool = false
param enableOryxBuild bool = contains(kind, 'linux')
param functionAppScaleLimit int = -1
param linuxFxVersion string = runtimeNameAndVersion
param minimumElasticInstanceCount int = -1
param numberOfWorkers int = -1
param scmDoBuildDuringDeployment bool = false
param use32BitWorkerProcess bool = false
param ftpsState string = 'FtpsOnly'
param healthCheckPath string = ''
param aadClientId string = ''
param tenantId string = subscription().tenantId

param logAnalyticsWorkspaceResourceId string = !empty(logAnalyticsWorkspaceName) ? resourceId('Microsoft.OperationalInsights/workspaces', logAnalyticsWorkspaceName) : ''

param isGovCloudDeployment bool  

param portalURL string = (isGovCloudDeployment) ? 'https://portal.azure.us' : 'https://portal.azure.com'

resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: name
  location: location
  tags: tags
  kind: kind
  properties: {
    serverFarmId: appServicePlanId
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      alwaysOn: alwaysOn
      ftpsState: ftpsState
      appCommandLine: appCommandLine
      numberOfWorkers: numberOfWorkers != -1 ? numberOfWorkers : null
      minimumElasticInstanceCount: minimumElasticInstanceCount != -1 ? minimumElasticInstanceCount : null
      use32BitWorkerProcess: use32BitWorkerProcess
      functionAppScaleLimit: functionAppScaleLimit != -1 ? functionAppScaleLimit : null
      healthCheckPath: healthCheckPath
      cors: {
        allowedOrigins: union([ portalURL, 'https://ms.portal.azure.com' ], allowedOrigins)
      }
    }
    clientAffinityEnabled: clientAffinityEnabled
    httpsOnly: true
  }

  identity: { type: managedIdentity ? 'SystemAssigned' : 'None' }

  resource configAppSettings 'config' = {
    name: 'appsettings'
    properties: union(appSettings,
      {
        SCM_DO_BUILD_DURING_DEPLOYMENT: toLower(string(scmDoBuildDuringDeployment))
        ENABLE_ORYX_BUILD: string(enableOryxBuild)
      },
      !empty(applicationInsightsName) ? { APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights.properties.ConnectionString } : {},
      !empty(keyVaultName) ? { AZURE_KEY_VAULT_ENDPOINT: keyVault.properties.vaultUri } : {})
  }

  resource configLogs 'config' = {
    name: 'logs'
    properties: {
      applicationLogs: { fileSystem: { level: 'Verbose' } }
      detailedErrorMessages: { enabled: true }
      failedRequestsTracing: { enabled: true }
      httpLogs: { fileSystem: { enabled: true, retentionInDays: 1, retentionInMb: 35 } }
    }
    dependsOn: [
      configAppSettings
    ]
  }

  resource authSettingsV2 'config' = {
    name: 'authsettingsV2'
    properties: {
      globalValidation: {
        unauthenticatedClientAction: 'RedirectToLoginPage'
        redirectToProvider: 'AzureActiveDirectory'
        requireAuthentication: true
      }
      identityProviders: {
        azureActiveDirectory: {
          enabled: true
          registration: {
            openIdIssuer: 'https://sts.windows.net/${tenantId}/v2.0'
            clientId: aadClientId
          }
          validation: {
            allowedAudiences: [
              'api://${name}'
            ]
            defaultAuthorizationPolicy: {
              allowedApplications: []
            }
          }
        }
      }
    }
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = if (!(empty(keyVaultName))) {
  name: keyVaultName
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
        retentionPolicy:  {
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

output identityPrincipalId string = managedIdentity ? appService.identity.principalId : ''
output name string = appService.name
output uri string = 'https://${appService.properties.defaultHostName}'
