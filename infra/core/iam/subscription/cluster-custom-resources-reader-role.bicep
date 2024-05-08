targetScope = 'subscription'

@description('Name of the Custom Role Definition in Azure.')
param roleName string

@description('ID of the Azure AD Service Principal.')
param principalId string = 'defaultforwhatif'

@description('ID of the Access group.')
param groupObjectId string = 'defaultforwhatif'

resource roleAssignmentSP 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, principalId, roleName)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleName)
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

resource roleAssignmentAG 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, groupObjectId, roleName)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleName)
    principalId: groupObjectId
    principalType: 'Group'
  }
}
