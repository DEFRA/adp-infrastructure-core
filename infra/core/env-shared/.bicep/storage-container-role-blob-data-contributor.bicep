@description('Required. The parameter for the managed identity principalId.')
param principalId string

@description('Required: Storage account object. The object must contain the following properties: name, containerName.')
param storageAccount object

resource storageAccountResource 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storageAccount.name
}

resource storageAccountBlobServices 'Microsoft.Storage/storageAccounts/blobServices@2021-04-01' existing = {
  name: 'default'
  parent: storageAccountResource
}

resource storageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' existing = {
  name: storageAccount.containerName
  parent: storageAccountBlobServices
}

resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, principalId, 'storageAccountContainerRoleAssignment')
  scope: storageContainer
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Storage Blob Data Contributor
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
