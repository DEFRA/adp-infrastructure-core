targetScope = 'subscription'

@sys.description('Required. Role definition fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
param roleDefinitionId string

@sys.description('Required. The Principal or Object ID of the Security Principal (User, Group, Service Principal, Managed Identity).')
param principalId string

@sys.description('Optional. The principal type of the assigned principal ID.')
param principalType string

@sys.description('Optional. The description of the role assignment.')
param description string

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, principalId, roleDefinitionId)
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: principalId
    principalType: principalType
    description: description
  }
}

@sys.description('The GUID of the Role Assignment.')
output name string = roleAssignment.name
