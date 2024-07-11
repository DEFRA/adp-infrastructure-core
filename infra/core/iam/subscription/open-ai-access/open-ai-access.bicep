targetScope = 'subscription'

@description('ID of the Reader Access group.')
param resourcesReaderGroupObjectId string

@description('ID of the Read Write Access group.')
param resourcesReadWriteGroupObjectId string

param deployOpenAIReaderRole string = 'false'
param deployOpenAIContributorRole string = 'false'

var readGroupObjectIdvar = empty(resourcesReaderGroupObjectId) ? 'defaultgroupObjectIdforwhatif' : resourcesReaderGroupObjectId
var writeGroupObjectIdvar = empty(resourcesReadWriteGroupObjectId) ? 'defaultgroupObjectIdforwhatif' : resourcesReadWriteGroupObjectId


resource openAIUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (deployOpenAIReaderRole == 'true') {
  name: guid(subscription().id, readGroupObjectIdvar, 'Cognitive Services OpenAI User')
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'Cognitive Services OpenAI User')
    principalId: readGroupObjectIdvar
    principalType: 'Group'
  }
}

resource openAIContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (deployOpenAIContributorRole == 'true') {
  name: guid(subscription().id, writeGroupObjectIdvar, 'Cognitive Services OpenAI Contributor')
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'Cognitive Services OpenAI Contributor')
    principalId: writeGroupObjectIdvar
    principalType: 'Group'
  }
}
