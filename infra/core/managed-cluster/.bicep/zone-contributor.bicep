@description('Required. The parameter object for the managed identity. The object must contain the name and principalId values.')
param managedIdentity object
@description('Required. The name of the private DNS zone.')
param privateDnsZoneName string

resource msiVnetRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, 'NetworkContributor', managedIdentity.name)
  scope: privateDnsZone
  properties: {
    principalId: managedIdentity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'befefa01-2a29-4197-83a8-272ff33ce314') // DNS Zone Contributor
    principalType: 'ServicePrincipal'
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
}
