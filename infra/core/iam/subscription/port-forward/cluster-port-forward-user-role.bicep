targetScope = 'subscription'

@description('Name of the Custom Role Definition in Azure.')
param roleName string

@description('ID of the Access group.')
param groupObjectId string

param deployClusterPortForwardRole bool = false

var groupObjectIdvar = empty(groupObjectId) ? 'defaultgroupObjectIdforwhatif' : groupObjectId


resource roleAssignmentAG 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (deployClusterPortForwardRole) {
  name: guid(subscription().id, groupObjectIdvar, roleName)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleName)
    principalId: groupObjectIdvar
    principalType: 'Group'
  }
}
