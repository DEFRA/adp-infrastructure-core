@description('Required. The parameter object for the managed identity. The object must contain the name and principalId values.')
param principalId string
@description('Required. The rbac role definition Id.')
param roleDefinitionId string

resource rsgGrpRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, 'Reader', resourceGroup().name)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId) 
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
