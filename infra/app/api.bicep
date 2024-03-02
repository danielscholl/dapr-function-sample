
param name string
param location string = resourceGroup().location
param tags object = {}
param serviceName string = 'api'
param managedIdentityName string 
param registryName string
param environmentName string
param imageName string

module api '../host/container-app.bicep' = {
  name: 'api'
  params: {
    name: name
    location: location
    tags: union(tags, { 'azd-service-name': 'api' })
    containerAppsEnvironmentName: environmentName
    containerRegistryName: registryName
    containerCpuCoreCount: '1.0'
    containerMemory: '2.0Gi'
    imageName: !empty(imageName) ? imageName : 'nginx:latest'
    daprEnabled: true
    containerName: serviceName
    targetPort: 7002
    managedIdentityEnabled: true
    managedIdentityName: managedIdentityName
  }
}

output SERVICE_API_IDENTITY_PRINCIPAL_ID string = api.outputs.identityPrincipalId
output SERVICE_API_NAME string = api.outputs.name
output SERVICE_API_URI string = api.outputs.uri
