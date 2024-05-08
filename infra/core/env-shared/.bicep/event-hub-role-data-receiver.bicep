@description('Required. The parameter for the managed identity principalId.')
param principalId string

@description('Required: Event Hub object. The object must contain the following properties: namespaceName, eventHubName.')
param eventHub object

resource namespace 'Microsoft.EventHub/namespaces@2022-10-01-preview' existing = {
  name: eventHub.namespaceName
}

resource eventHubResource 'Microsoft.EventHub/namespaces/eventhubs@2022-10-01-preview' existing = {
  name: eventHub.eventHubName
  parent: namespace
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, 'azureEventHubDataReceiverRoleAssignment')
  scope: eventHubResource
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a638d3c7-ab3a-418d-83e6-5f17a39d4fde') // Azure Event Hubs Data Receiver
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
