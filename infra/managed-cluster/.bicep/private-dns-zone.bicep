@description('Required. The parameter object for the virtual network. The object must contain the name and resourceGroup values.')
param vnet object
@description('Required. The parameter object for the managed identity. The object must contain the name and principalId values.')
param managedIdentity object
@description('Required. The name of the private DNS zone.')
param privateDnsZoneName string
@description('Required. The tags to associate with the private DNS zone.')
param tags object

var pdnsTags = { 
  Name: privateDnsZoneName
  Purpose: 'AKS Private DNS Zone'
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  tags: union(tags, pdnsTags)
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

@description('Private DNS Zone ID')
output privateDnsZoneId string = privateDnsZone.id
