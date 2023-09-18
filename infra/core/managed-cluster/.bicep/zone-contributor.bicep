@description('Required. The parameter object for the managed identity. The object must contain the name and principalId values.')
param managedIdentity object
@description('Required. The name of the private DNS zone.')
param privateDnsZoneName string

resource msiVnetRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, 'NetworkContributor', managedIdentity.name)
  scope: privateDnsZone
  properties: {
    principalId: managedIdentity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b12aa53e-6015-4669-85d0-8515ebb3ae7f') // Private DNS Zone Contributor
    principalType: 'ServicePrincipal'
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZoneName
}

@description('The resource id of the private DNS zone.')
output privateDnsZoneResourceId string = privateDnsZone.id
