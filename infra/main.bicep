targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@minLength(3)
@maxLength(20)
@description('Used to name all resources')
param resourceName string = 'sample'


#disable-next-line no-unused-vars
var resourceToken = (uniqueString(subscription().id, environmentName, location))
var resourceGroupName = '${environmentName}-${resourceName}-${resourceToken}'
var uniqueValue = '${replace(configuration.name, '-', '')}${uniqueString(group.outputs.resourceId, configuration.name)}'

@description('Configuration Object')
var configuration = {
  name: 'sample'
  displayName: 'DAPR Sample Resources'
  tags: {
    'azd-env-name': environmentName
  }
  telemetry: false
  lock: {}
  logs: {
    sku: 'PerGB2018'
    retentionInDays: 30
  }
  storage: {
    sku: 'Standard_LRS'
  }
  insights: {
    sku: 'web'
  }
  cache: {
    capacity: 1
    sku: 'Basic'
  }
  services: [
    {
      name: 'hello-world'
      cpu: '0.25'
      memory: '0.5Gi'
      dapr: {}
    }
    {
      name: 'api'
      cpu: '0.25'
      memory: '0.5Gi'
      dapr: {}
    }
  ]
}

module group 'br/public:avm/res/resources/resource-group:0.2.3' = {
  name: resourceGroupName
  params: {
    name: resourceGroupName
    location: location
    lock: configuration.lock
    tags: configuration.tags
    enableTelemetry: configuration.telemetry
  }
}

module managedidentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.1.3' = {
  name: '${configuration.name}-user-managed-identity'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: '${uniqueValue}mi'
    location: location
    lock: configuration.lock
    tags: configuration.tags
    enableTelemetry: configuration.telemetry
  }
}

module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.2.1' = {
  name: '${configuration.name}-log-analytics'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: '${uniqueValue}la'
    location: location
    lock: configuration.lock
    tags: configuration.tags
    enableTelemetry: configuration.telemetry

    skuName: configuration.logs.sku
    dataRetention: configuration.logs.retentionInDays
  }
}

module storageAccount 'br/public:avm/res/storage/storage-account:0.6.6' = {
  name: '${configuration.name}-storage-account'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: '${uniqueValue}sa'
    skuName: configuration.storage.sku
    location: location
    enableTelemetry: configuration.telemetry

    roleAssignments: [
      {
        principalId: managedidentity.outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Contributor'
      }
    ]

    diagnosticSettings: [
      {
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
        name: 'customSetting'
        workspaceResourceId: logAnalytics.outputs.resourceId
      }
    ]
  }
}

module registry 'br/public:avm/res/container-registry/registry:0.1.0' = {
  name: '${configuration.name}-container-registry'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: '${uniqueValue}cr'
    location: location
    enableTelemetry: configuration.telemetry

    acrAdminUserEnabled: true

    roleAssignments: [
      {
        principalId: managedidentity.outputs.principalId
        roleDefinitionIdOrName: 'AcrPull'
      }
    ]

    diagnosticSettings: [
      {
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
        name: 'customSetting'
        workspaceResourceId: logAnalytics.outputs.resourceId
      }
    ]
  }
}

module redis 'br/public:avm/res/cache/redis:0.1.1' = {
  name: '${configuration.name}-redis-cache'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: '${uniqueValue}rc'
    location: location
    enableTelemetry: configuration.telemetry
    capacity: configuration.cache.capacity
    skuName: configuration.cache.sku

    diagnosticSettings: [
      {
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
        name: 'customSetting'
        workspaceResourceId: logAnalytics.outputs.resourceId
      }
    ]

    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Redis Cache Contributor'
        principalId: managedidentity.outputs.principalId
        principalType: 'ServicePrincipal'
      }
    ]
  }
}

module insights 'br/public:avm/res/insights/component:0.2.1' = {
  name: '${configuration.name}-insights'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: '${uniqueValue}ai'
    location: location
    enableTelemetry: configuration.telemetry
    kind: configuration.insights.sku
    workspaceResourceId: logAnalytics.outputs.resourceId
    
    diagnosticSettings: [
      {
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
        name: 'customSetting'
        workspaceResourceId: logAnalytics.outputs.resourceId
      }
    ]
  }
}

module containerEnvironment 'br/public:avm/res/app/managed-environment:0.4.3' = {
  name: '${configuration.name}-container-app-env'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: '${uniqueValue}e'
    location: location
    enableTelemetry: configuration.telemetry

    roleAssignments: [
      {
        roleDefinitionIdOrName: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
        principalId: managedidentity.outputs.principalId
        principalType: 'ServicePrincipal'
      }
    ]

    logAnalyticsWorkspaceResourceId: logAnalytics.outputs.resourceId
    daprAIInstrumentationKey: insights.outputs.instrumentationKey
  }
}

module daprComponents 'dapr-components.bicep' = {
  name: '${configuration.name}-dapr-components'
  scope: resourceGroup(resourceGroupName)
  params:{
    managedEnvironmentName: containerEnvironment.outputs.name
    redisCacheName: redis.outputs.name
  }
  dependsOn: [
    containerEnvironment
  ]
}

module containerapp 'container-app.bicep' = [for service in configuration.services: {
  name: 'container-${service.name}'
  scope: resourceGroup(resourceGroupName)
  params: {
    resourceName: configuration.name
    service: {
      name: service.name
      cpu: service.cpu
      memory: service.memory
    }
    dapr: !empty(service.dapr) ? service.dapr : null
    tags: configuration.tags
    lock: configuration.lock
    enableTelemetry: configuration.telemetry
    environmentName: containerEnvironment.outputs.name
    registryName: registry.outputs.name
    identityName: managedidentity.outputs.name
  }
  dependsOn: [
    daprComponents
  ]
}]

output AZURE_CONTAINER_REGISTRY_ENDPOINT string = registry.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = registry.outputs.name

// output MANAGED_IDENTITY_CLIENT_ID string = managedidentity.outputs.clientId
// output AZURE_LOG_ANALYTICS_WORKSPACE_NAME string = logAnalytics.outputs.name
// output AZURE_CONTAINER_REGISTRY_MANAGED_IDENTITY_ID string = managedidentity.outputs.resourceId

// output AZURE_CONTAINER_APPS_ENVIRONMENT_ID string = managedEnvironment.outputs.resourceId
// output AZURE_CONTAINER_APPS_ENVIRONMENT_DEFAULT_DOMAIN string = managedEnvironment.outputs.defaultDomain

