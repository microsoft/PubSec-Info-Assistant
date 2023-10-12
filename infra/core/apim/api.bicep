param apimName string
param apiName string
param apiPath string
param openApiJson string
param openApiXml string
param serviceUrl string
param apiSubscriptionName string

resource parentAPIM 'Microsoft.ApiManagement/service@2023-03-01-preview' existing = {
  name: apimName
}

resource api 'Microsoft.ApiManagement/service/apis@2023-03-01-preview' = {
  parent: parentAPIM
  name: apiName
  properties: {
    format: 'openapi+json-link'
    value: openApiJson
    path: apiPath
    serviceUrl: serviceUrl
  }
}

resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2023-03-01-preview' = {
  parent: api
  name: 'policy'
  properties: {
    format: 'xml-link'
    value: openApiXml
  }
}

resource apiSubscription 'Microsoft.ApiManagement/service/subscriptions@2023-03-01-preview' = {
  name: apiSubscriptionName
  parent: parentAPIM
  properties: {
    allowTracing: false
    displayName: apiSubscriptionName
    ownerId: '/users/1'
    scope: api.id
    state: 'active'
  }
}
