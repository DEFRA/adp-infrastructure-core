targetScope = 'subscription'

@description('Name of the Custom Role Definition in Azure.')
param roleName string

param principalId string

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')


module clustercustomRoleAssignment '../.bicep/role-assignment.bicep' = {
  name: 'clustercustomRoleAssignment-${deploymentDate}'
  params: {
    principalId: principalId
    roleDefinitionId: subscriptionResourceId(subscription().subscriptionId, 'Microsoft.Authorization/roleDefinitions', roleName)
  }
}
