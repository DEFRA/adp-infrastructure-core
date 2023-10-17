@description('Required. The parameter object for the virtual network. The object must contain the name and resourceGroup values.')
param vnet object

@description('Required. The prefix for the private DNS zone.')
param privateDnsZonePrefix string

@description('Required. Environment name.')
param environment string

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

var privateDnsZoneName = toLower('${privateDnsZonePrefix}.private.postgres.database.azure.com')
var commonTags = {
  Location: 'global'
  CreatedDate: createdDate
  Environment: environment
}
var tags = union(loadJsonContent('../../common/default-tags.json'), commonTags)

var dnsTags = {
  Name: privateDnsZoneName
  Purpose: 'ADP PostgreSQL Private DNS Zone'
}
var dnsVnetLinksTags = {
  Name: vnet.name
  Purpose: 'ADP PostgreSQL Private DNS Zone VNet Link'
}

module privateDnsZoneModule 'br/SharedDefraRegistry:network.private-dns-zone:0.5.2' = {
  name: 'postgresql-private-dns-zone-${deploymentDate}'
  params: {
   name: privateDnsZoneName  
   tags: union(tags, dnsTags)
   virtualNetworkLinks: [
    {
      name: vnet.name
      virtualNetworkResourceId: resourceId(vnet.resourceGroup, 'Microsoft.Network/virtualNetworks', vnet.name)
      registrationEnabled: true
      tags: union(tags, dnsVnetLinksTags)
    }
   ]
  }
}

