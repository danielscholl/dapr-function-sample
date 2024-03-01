param prefix string 
param location string = resourceGroup().location
param containerImage string
param containerPort int = 5501
param isExternalIngress bool = true 
param env array = []
param minReplicas int = 1
// param resourceToken string = toLower(uniqueString(subscription().id, prefix, location))
param managedIdentityName string 
param registryName string
param environmentId string


@allowed([
  'multiple'
  'single'
])
param revisionMode string = 'multiple'

var cpu = json('0.5')
var memory = '1Gi'
var appName = '${prefix}api'

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = {
  name: registryName
}



resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: managedIdentityName
}

resource api 'Microsoft.App/containerApps@2022-03-01' = {
  name: appName
  location: location
  tags: {
    'azd-env-name': prefix
    'azd-service-name': 'api'
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}' : {}
    }    
  }
  properties: {
    managedEnvironmentId: environmentId
    configuration: {
      activeRevisionsMode: revisionMode
      ingress: {
        external: isExternalIngress
        targetPort: containerPort
        transport: 'auto'
      }
      dapr: {
        enabled: true
        appPort: containerPort
        appProtocol: 'grpc'
        appId: appName
      }
      secrets: [
        {
          name: 'registry-password'
          value: containerRegistry.listCredentials().passwords[0].value
        }
      ]
      registries: [
        {
          server: '${containerRegistry.name}.azurecr.io'
          username: containerRegistry.name
          passwordSecretRef: 'registry-password'
        }
      ]
    }
    template: {
      containers: [
        {
          image: containerImage
          name: appName
          env: env
          resources: {
             cpu: cpu
             memory: memory
          }
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: minReplicas
      }
    }
  }
}

output API_URI string = 'https://${api.properties.configuration.ingress.fqdn}'