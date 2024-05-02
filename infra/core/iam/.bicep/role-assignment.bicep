targetScope = 'subscription'

@description('Required. The parameter object for the managed identity. The object must contain the name and principalId values.')
param principalId string

@description('Required. The role Definition Id.')
param roleDefinitionId string

@description('Optional. The principalType defaults to ServicePrincipal.')
param principalType string = 'ServicePrincipal'



resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, principalId, roleDefinitionId)
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: principalId
    principalType: principalType
  }
}
