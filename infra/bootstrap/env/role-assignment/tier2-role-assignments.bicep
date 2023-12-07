@description('Required. Environment specfic subscription Id')
param subscriptionId string

@description('Required. The Principal or Object ID of the Service Principal.')
param principalId string

@description('Optional. The principal type of the assigned principal ID.')
param principalType string = 'ServicePrincipal'

@description('Required. The parameter object for the subcription RoleAssignments. The object must contain the roleAssignmentDescription, roleDefinitionName values.')
param subcriptionRoleAssignments array

@description('Required. The parameter object for the container registry. The object must contain the name, subscriptionId and resourceGroup values.')
param sharedContainerRegistry object

var builtInRoleNames = {
  Contributor: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  'UserAccessAdministrator': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9')
}

module subscriptionContUAA '.bicep/subscription-rbac.bicep' = [for (roleAssignment, index) in subcriptionRoleAssignments: {
  scope: subscription(subscriptionId)
  name: '${uniqueString(deployment().name, subscription().id)}-Subscription-${roleAssignment.roleDefinitionName}-${index}'
  params: {
    principalId: principalId
    principalType: principalType
    description: !empty(roleAssignment.roleAssignmentDescription) ? roleAssignment.roleAssignmentDescription : null
    roleDefinitionId: builtInRoleNames[roleAssignment.roleDefinitionName]
  }
}]

module ssvResourceGroupContributor '.bicep/shared-resourcegroup-contributor.bicep' = {
  scope: resourceGroup(sharedContainerRegistry.subscriptionId, sharedContainerRegistry.resourceGroup)
  name: '${uniqueString(deployment().name, subscription().id)}-ssvResourceGroupContributor'
  params: {
    principalId: principalId
    principalType: principalType
    description: 'Contributor role assignment to ssv resource group'
    roleDefinitionId: builtInRoleNames['Contributor'] //Contributor
  }
}

module ssvACRUserAccessAdministrator '.bicep/shared-acr-uaa.bicep' = {
  scope: resourceGroup(sharedContainerRegistry.subscriptionId, sharedContainerRegistry.resourceGroup)
  name: '${uniqueString(deployment().name, subscription().id)}-ssvACRUserAccessAdministrator'
  params: {
    principalId: principalId
    principalType: principalType
    description: 'UAA role assignment to shared ACR'
    roleDefinitionId: builtInRoleNames['UserAccessAdministrator'] //User Access Administrator
    containerRegistryName: sharedContainerRegistry.name
  }
}
