targetScope = 'subscription'

@description('ID of the Access group.')
param resourcesDataAccessGroupObjectId string

@description('Role Name to be deployed.')
param openAIDataAccessRole string = 'Cognitive Services OpenAI User'

var groupObjectIdvar = empty(resourcesDataAccessGroupObjectId) ? 'defaultgroupObjectIdforwhatif' : resourcesDataAccessGroupObjectId


resource openAIUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (openAIDataAccessRole == 'Cognitive Services OpenAI User') {
  name: guid(subscription().id, groupObjectIdvar, 'Cognitive Services OpenAI User')
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd')
    principalId: groupObjectIdvar
    principalType: 'Group'
  }
}

resource openAIContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (openAIDataAccessRole == 'Cognitive Services OpenAI Contributor') {
  name: guid(subscription().id, groupObjectIdvar, 'Cognitive Services OpenAI Contributor')
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'a001fd3d-188f-4b5d-821b-7da978bf7442')
    principalId: groupObjectIdvar
    principalType: 'Group'
  }
}
