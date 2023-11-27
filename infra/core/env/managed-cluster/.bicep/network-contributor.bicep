@description('Required. The parameter object for the managed identity. The object must contain the name and principalId values.')
param managedIdentity object
@description('Required. The name of the vnet')
param vnetName string

resource msiVnetRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, 'NetworkContributor', managedIdentity.name)
  scope: virtualNetwork
  properties: {
    principalId: managedIdentity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4d97b98b-1d4f-4787-a291-c67834d212e7') // Network Contributor
    principalType: 'ServicePrincipal'
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  name: vnetName
}
