param location string = resourceGroup().location
param logWorkbookName string = ''
param componentResource string = ''

resource logworkbook 'Microsoft.Insights/workbooktemplates@2020-11-20' = {
  name: logWorkbookName
  location: location
  properties: {
    galleries: [
      {
        category: 'Deployed Template'
        name: logWorkbookName
        order: 1
        resourceType: 'Azure Monitor'
        type: 'workbook'
      }
    ]
    priority: 1
    templateData: {
  version: 'Notebook/1.0'
  items: [
    {
      type: 1
      content: {
        json: '\r\n\r\nApplication Logs (Last 6 Hours)'
      }
      name: 'text - 3'
    }
    {
      type: 3
      content: {
        version: 'KqlItem/1.0'
        query: 'AppServiceConsoleLogs | project TimeGenerated, Level, ResultDescription, _ResourceId | where TimeGenerated > ago(6h) | order by TimeGenerated desc'
        size: 0
        timeContext: {
          durationMs: 86400000
        }
        queryType: 0
        resourceType: 'microsoft.operationalinsights/workspaces'
        crossComponentResources: [
          componentResource
        ]
      }
      name: 'App Logs'
    }
    {
      type: 1
      content: {
        json: 'Function Logs (Last 6 Hours)'
      }
      name: 'text - 4'
    }
    {
      type: 3
      content: {
        version: 'KqlItem/1.0'
        query: 'AppTraces | project TimeGenerated, Message, Properties | where TimeGenerated > ago(6h) | order by TimeGenerated desc'
        size: 0
        timeContext: {
          durationMs: 86400000
        }
        queryType: 0
        resourceType: 'microsoft.operationalinsights/workspaces'
        crossComponentResources: [
          componentResource
        ]
      }
      name: 'query - 1'
    }
    {
      type: 1
      content: {
        json: 'App Service Deployment Logs (Last 6 Hours)'
      }
      name: 'text - 5'
    }
    {
      type: 3
      content: {
        version: 'KqlItem/1.0'
        query: 'AppServicePlatformLogs | project TimeGenerated, Level, Message, _ResourceId | where TimeGenerated > ago(6h) | order by TimeGenerated desc'
        size: 0
        timeContext: {
          durationMs: 86400000
        }
        queryType: 0
        resourceType: 'microsoft.operationalinsights/workspaces'
        crossComponentResources: [
          componentResource
        ]
      }
      name: 'query - 2'
    }
  ]
  fallbackResourceIds: [
    'Azure Monitor'
  ]
}
  }
}
