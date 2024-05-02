targetScope = 'subscription'

@description('Name of the Custom Role Definition in Azure.')
param roleName string

param principalId string

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, principalId, roleName)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleName)
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
