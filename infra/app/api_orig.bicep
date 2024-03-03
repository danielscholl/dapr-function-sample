
param name string
param location string = resourceGroup().location
param tags object = {}
param serviceName string = 'api'
param managedIdentityName string 
param registryName string
param environmentId string
param imageName string

module containerApp 'br/public:avm/res/app/container-app:0.1.3' = {
  name: 'api'
  params: {
    name: name
    location: location
    tags: union(tags, { 'azd-service-name': 'api' })
    enableTelemetry: false

    // Required parameters
    containers: [
      {
        image: !empty(imageName) ? imageName : 'nginx:latest'
        name: serviceName
        targetPort: 7002
        managedIdentity: {
          enabled: true
          name: managedIdentityName
        }
        resources: {
          cpu: '1.0'
          memory: '2.0Gi'
        }    
      }
    ]
    environmentId: environmentId

     registries: [
      {
        server: '${registryName}.azurecr.io'
        username: registryName
        passwordSecretRef: 'registry-password'
      }
    ]  
    
  }
}

// module api '../host/container-app.bicep' = {
//   name: 'api2'
//   params: {
//     name: name
//     location: location
//     tags: union(tags, { 'azd-service-name': 'api' })
//     containerAppsEnvironmentName: environmentName
//     containerRegistryName: registryName
//     containerCpuCoreCount: '1.0'
//     containerMemory: '2.0Gi'
//     imageName: !empty(imageName) ? imageName : 'nginx:latest'
//     daprEnabled: true
//     containerName: serviceName
//     targetPort: 7002
//     managedIdentityEnabled: true
//     managedIdentityName: managedIdentityName
//   }
// }

// output SERVICE_API_IDENTITY_PRINCIPAL_ID string = api.outputs.identityPrincipalId
output SERVICE_API_NAME string = containerApp.outputs.name
// output SERVICE_API_URI string = containerApp.outputs.uri
