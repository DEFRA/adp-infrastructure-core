@description('Required. The parameter object for the virtual network. The object must contain the name and resourceGroup values.')
param vnet object

@description('Required. The prefix for the private DNS zone.')
param privateDnsZonePrefix string

@allowed([
  'UKSouth'
])
@description('Required. The Azure region where the resources will be deployed.')
param location string

@description('Required. Environment name.')
param environment string

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

var privateDnsZoneName = toLower('${environment}.internal.${location}.adp.defra.gov.uk')
var commonTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}
var tags = union(loadJsonContent('../../default-tags.json'), commonTags)

var dnsTags = {
  Name: privateDnsZoneName
  Purpose: 'Private DNS Zone'
}
var dnsVnetLinksTags = {
  Name: vnet.name
  Purpose: 'Private DNS Zone VNet Link'
}

module privateDnsZoneModule 'br/SharedDefraRegistry:network.private-dns-zone:0.5.2' = {
  name: 'private-dns-zone-${deploymentDate}'
  params: {
   name: privateDnsZoneName  
   lock: 'CanNotDelete'
   tags: union(tags, dnsTags)
   virtualNetworkLinks: [
    {
      name: vnet.name
      virtualNetworkResourceId: resourceId(vnet.resourceGroup, 'Microsoft.Network/virtualNetworks', vnet.name)
      registrationEnabled: false
      tags: union(tags, dnsVnetLinksTags)
    }
   ]
  }
}

