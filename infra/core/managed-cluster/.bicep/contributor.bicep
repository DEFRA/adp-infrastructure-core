targetScope = 'subscription'

@description('Required. The principal id for the managed identity.')
param principalId string

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, principalId, 'contributor')
  scope: subscription()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
