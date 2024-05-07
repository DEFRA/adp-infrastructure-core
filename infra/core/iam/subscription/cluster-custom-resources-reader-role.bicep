targetScope = 'subscription'

@description('Name of the Custom Role Definition in Azure.')
param roleName string

@description('ID of the Azure AD Service Principal.')
param principalId string

@allowed([
  'ServicePrincipal'
  'Group'
  'User'])
param principalType string = 'ServicePrincipal'

resource roleAssignmentSP 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, principalId, roleName)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleName)
    principalId: principalId
    principalType: principalType
  }
}
