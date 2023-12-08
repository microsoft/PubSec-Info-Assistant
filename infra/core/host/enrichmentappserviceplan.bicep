param name string
param location string = resourceGroup().location
param tags object = {}

param kind string = ''
param reserved bool = true
param sku object

param storageAccountId string


// Create an App Service Plan to group applications under the same payment plan and SKU, specifically for containers
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: name
  location: location
  tags: tags
  sku: sku
  kind: kind
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 3
    isSpot: false
    reserved: reserved
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
              metricResourceUri: storageAccountId
              operator: 'GreaterThan'
              statistic: 'Average'
              threshold: 5
              timeAggregation: 'Average'
              timeGrain: 'PT1M'
              timeWindow: 'PT10M'
            }
          }
          {
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
            metricTrigger: {
              metricName: 'ApproximateMessageCount'
              metricNamespace: ''
              metricResourceUri: storageAccountId
              operator: 'LessThan'
              statistic: 'Average'
              threshold: 2
              timeAggregation: 'Average'
              timeGrain: 'PT1M'
              timeWindow: 'PT10M'
            }
          }
        ]
      }
    ]
    targetResourceUri: appServicePlan.id
  }
}

output id string = appServicePlan.id
output name string = appServicePlan.name
