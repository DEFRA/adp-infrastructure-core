@description('Required. The parameter object for eventHub. The object must contain the namespaceName and eventHubName values.')
param eventHub object

resource namespace 'Microsoft.EventHub/namespaces@2022-10-01-preview' existing = {
  name: eventHub.namespaceName
}

resource eventHubResource 'Microsoft.EventHub/namespaces/eventhubs@2022-10-01-preview' = {
  name: eventHub.eventHubName
  parent: namespace
}
