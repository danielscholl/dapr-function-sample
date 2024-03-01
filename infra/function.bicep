param prefix string
param location string
param appInsightsConnectionString string
param environmentId string
param stateStoreName string
param storageAccountName string
param imageName string

resource daprComponentStateManagement 'Microsoft.App/managedEnvironments/daprComponents@2023-05-01' existing = {
  name: stateStoreName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

var azStorageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${az.environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'


/* ###################################################################### */
// Create Azure Function
/* ###################################################################### */
resource azfunctionapp 'Microsoft.Web/sites@2023-01-01' = {
  name: '${prefix}-funcapp'
  location: location
  kind: 'functionapp,linux,container,azurecontainerapps'
  properties: {
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: azStorageConnectionString
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'StateStoreName'
          value: 'statestore'
        }
      ]
      linuxFxVersion: 'Docker|${imageName}'  
    }
    daprConfig: {
      enabled: true
      appId: '${prefix}-funcapp'
      appPort: 3001
      httpReadBufferSize: ''
      httpMaxRequestSize: ''
      logLevel: ''
      enableApiLogging: true
    }
    managedEnvironmentId: environmentId
  }
  dependsOn: [
    daprComponentStateManagement
  ]
}
