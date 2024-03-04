@description('Required. The parameter object for the managed identity. The object must contain the name and principalId values.')
param principalId string
@description('Required. The name of the key vault.')
param keyVaultName string
@description('Required. The name of the key vault secret name.')
param secretName string

resource vault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' existing = {
  parent: vault
  name: secretName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, secretName)
  scope: secret
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
