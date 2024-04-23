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
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b') // Storage Blob Data Contributor
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
