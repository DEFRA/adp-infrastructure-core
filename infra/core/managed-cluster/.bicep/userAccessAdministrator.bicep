targetScope = 'subscription'

@description('Required. The principal id for the managed identity.')
param principalId string

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, principalId, 'userAccessAdministrator')
  scope: subscription()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9') // User Access Administrator
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
