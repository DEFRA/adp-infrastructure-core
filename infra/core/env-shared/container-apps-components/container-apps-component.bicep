@description('Required: The name of the container app managed environment.')
param containerAppEnvironmentName string

@description('Required: The flux notification managed identity name')
param managedIdentityName string

@description('Required: The container app ID')
param containerAppId string

@description('Required: The event hub namespace name')
param eventHubNamespaceName string

@description('Required: The flux notification storage account name')
param storageAccountName string

resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: containerAppEnvironmentName
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedIdentityName
}

resource eventHubsComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-03-01' = {
  name: 'pubsub'
  parent: containerAppEnvironment
  properties: {
    componentType: 'pubsub.azure.eventhubs'
    version: 'v1'
    metadata: [
      {
        name: 'azureClientID'
        value: managedIdentity.properties.clientId
      }
      {
        name: 'consumerGroup'
        value: containerAppId
      }
      {
        name: 'eventHubNamespace'
        value: eventHubNamespaceName
      }
      {
        name: 'storageAccountName'
        value: storageAccountName
      }
      {
        name: 'storageContainerName'
        value: containerAppId
      }
      {
        name: 'enableEntityManagement'
        value: 'false'
      }
    ]
    scopes: [
      containerAppId
    ]
  }
}

