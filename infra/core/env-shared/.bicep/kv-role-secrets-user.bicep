@description('Required. The parameter object for the managed identity. The object must contain the name and principalId values.')
param principalId string
@description('Required. The name of the key vault.')
param keyVaultName string

resource vault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, 'kvsecretsuser')
  scope: vault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
