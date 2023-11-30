@description('Required. The principal id for the managed identity.')
param principalId string
@description('Required. The name of the app configuration service.')
param keyVaultName string
@description('Required. The role definition Id to be granted to the managed identity.')
param roleDefinitionId string

resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' existing = {
  name: keyVaultName
}

resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, roleDefinitionId, keyVaultName)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId) 
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
