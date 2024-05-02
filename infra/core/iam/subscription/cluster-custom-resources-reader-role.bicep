

@description('Name of the Custom Role Definition in Azure.')
param roleName string

param principalId string

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

resource customRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: roleName
}

module clustercustomRoleAssignment '../.bicep/role-assignment.bicep' = {
  name: '${roleName}-${deploymentDate}'
  params: {
    principalId: principalId
    roleDefinitionId: customRoleDefinition.id
  }
}
