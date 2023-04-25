param logAnalyticsName string
param applicationInsightsName string
param location string = resourceGroup().location
param tags object = {}

param skuName string = 'PerGB2018'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: skuName
    }
  }
}

resource applicatoinInsights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: applicationInsightsName
  location: location
  tags: tags
  kind: 'web'
  
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

output applicationInsightsId string = applicatoinInsights.id
output logAnalyticsId string = logAnalytics.id
output applicationInsightsName string = applicatoinInsights.name
output logAnalyticsName string = logAnalytics.name
output applicationInsightsInstrumentationKey string = applicatoinInsights.properties.InstrumentationKey
