targetScope = 'subscription'

@description('ID of the Global reader Access group.')
param globalReaderGroupObjectId string

var groupObjectIdvar = empty(globalReaderGroupObjectId) ? 'defaultgroupObjectIdforwhatif' : globalReaderGroupObjectId

resource openAIUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, groupObjectIdvar, 'Reader')
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
    principalId: groupObjectIdvar
    principalType: 'Group'
  }
}
