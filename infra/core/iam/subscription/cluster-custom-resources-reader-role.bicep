targetScope = 'subscription'

@description('Name of the Custom Role Definition in Azure.')
param roleName string

@description('ID of the Azure AD Service Principal.')
param principalId string

@description('ID of the Access group.')
param groupObjectId string

var principalIdvar = empty(principalId) ? 'defaultprincipalIdforwhatif' : principalId
var groupObjectIdvar = empty(groupObjectId) ? 'defaultgroupObjectIdforwhatif' : groupObjectId

resource roleAssignmentSP 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, principalIdvar, roleName)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleName)
    principalId: principalIdvar
    principalType: 'ServicePrincipal'
  }
}

resource roleAssignmentAG 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, groupObjectIdvar, roleName)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleName)
    principalId: groupObjectIdvar
    principalType: 'Group'
  }
}
