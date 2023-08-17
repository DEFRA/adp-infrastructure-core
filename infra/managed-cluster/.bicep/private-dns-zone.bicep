param vnet object
param managedIdentity object
param privateDnsZoneName string

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
}

resource privateDNSZoneVNetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${vnet.name}'
  location: 'global'
  parent: privateDnsZone
  properties: {
      registrationEnabled: true
      virtualNetwork: {
          id: resourceId(vnet.resourceGroup, 'Microsoft.Network/virtualNetworks', vnet.name)
      }
  }
}

resource msiPrivDnsZoneRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, 'PrivateDNSZoneContributor', managedIdentity.name)
  scope: privateDnsZone
  properties: {
      principalId: managedIdentity.principalId
      roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b12aa53e-6015-4669-85d0-8515ebb3ae7f') // Private DNS Zone Contributor
      principalType: 'ServicePrincipal'
  }
}
