// param redisCacheName string
param managedEnvironmentName string
param storageAccountName string
param containerName string

resource environment 'Microsoft.App/managedEnvironments@2022-10-01' existing = {
  name: managedEnvironmentName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

/* ###################################################################### */
// Setup Dapr componet Blob state store in ACA
/* ###################################################################### */
resource daprComponentStateManagement 'Microsoft.App/managedEnvironments/daprComponents@2023-05-01' = {
  parent: environment
  name: 'statestore'
  properties: {
    componentType: 'state.azure.blobstorage'
    version: 'v1'
    metadata: [
      {
        name: 'accountName'
        value: storageAccount.name
      }
      {
        name: 'accountKey'
        value: storageAccount.listKeys().keys[0].value
      }
      {
        name: 'containerName'
        value: containerName
      }
    ]
    scopes: []
  }
}

output stateStoreName string = 'statestore'
