
type resourcesProperty = {
  @description('The cpu value')
  cpu: string
  @description('The memory value')
  memory: string
}

type ingressProperty = {
  @description('Enable external ingress')
  external: bool
  @description('Ingress Port')
  port: int
}

@minLength(3)
@maxLength(20)
@description('Used to name all resources')
param resourceName string

param name string
param environmentName string
param registryName string
param identityName string
param image string = ''
param tags object
param enableTelemetry bool
param lock object


param resources resourcesProperty
param ingress ingressProperty = {
  external: false
  port: 80
}

@description('Optional. Dapr configuration for the Container App.')
param dapr object = {}


resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: environmentName
}

// 2022-02-01-preview needed for anonymousPullEnabled
resource registry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = {
  name: registryName
}

// user assigned managed identity to use throughout
resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: identityName
}


module containerApp 'br/public:avm/res/app/container-app:0.1.3' = {
  name: '${resourceName}-container-app-${name}'
  params: {
    name: name
    ingressExternal: ingress.external
    ingressAllowInsecure: false
    ingressTargetPort: ingress.port
    lock: lock
    tags: union(tags, { 'azd-service-name': name })
    enableTelemetry: enableTelemetry

    environmentId: containerAppsEnvironment.id
    managedIdentities: {
      userAssignedResourceIds: [
        identity.id
      ]
    }
    secrets: {
      secureList: []
    }

    registries: [
      {
        server: '${registry.name}.azurecr.io'
        identity: identity.id
      }
    ] 

    dapr: !empty(dapr) ? dapr : null

    // Required parameters
    containers: [
      {
        name: '${name}-container'
        image: !empty(image) ? image : 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
        resources: {
          // workaround as 'float' values are not supported in Bicep, yet the resource providers expects them. Related issue: https://github.com/Azure/bicep/issues/1386
          cpu: json(resources.cpu)
          memory: resources.memory
        }
        // probes: [
        //   {
        //     type: 'Liveness'
        //     httpGet: {
        //       path: '/health'
        //       port: 8080
        //       httpHeaders: [
        //         {
        //           name: 'Custom-Header'
        //           value: 'Awesome'
        //         }
        //       ]
        //     }
        //     initialDelaySeconds: 3
        //     periodSeconds: 3
        //   }
        // ]
      }
    ]    
  }
}

output name string = containerApp.name

