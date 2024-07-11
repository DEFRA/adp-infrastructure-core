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
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd')
    principalId: readGroupObjectIdvar
    principalType: 'Group'
  }
}

resource openAIContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (deployOpenAIContributorRole == 'true') {
  name: guid(subscription().id, writeGroupObjectIdvar, 'Cognitive Services OpenAI Contributor')
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'a001fd3d-188f-4b5d-821b-7da978bf7442')
    principalId: writeGroupObjectIdvar
    principalType: 'Group'
  }
}
