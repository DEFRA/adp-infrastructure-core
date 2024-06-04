@description('Required. The principal id for the managed identity.')
param principalId string
@description('Required. The name of the Open AI service.')
param openAiName string

resource openAi 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' existing = {
  name: openAiName
}

resource openAiRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, openAiName)
  scope: openAi
  properties: {
    roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
