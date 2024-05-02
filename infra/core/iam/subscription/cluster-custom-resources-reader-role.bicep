targetScope = 'subscription'

@description('Name of the Custom Role Definition in Azure.')
param roleName string

param principalId string



resource customRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: roleName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, principalId, customRoleDefinition.id)
  scope: subscription()
  properties: {
    roleDefinitionId: customRoleDefinition.id
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}


// module clustercustomRoleAssignment '../.bicep/role-assignment.bicep' = {
//   name: '${roleName}-${deploymentDate}'
//   params: {
//     principalId: principalId
//     roleDefinitionId: customRoleDefinition.id
//   }
// }
