@description('Required. The parameter object for the virtual network. The object must contain the name and resourceGroup values.')
param vnet object

@description('Required. The private DNS zone.')
param privateDnsZone string

@description('Required. Environment name.')
param environment string

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

var privateDnsZoneName = (privateDnsZone == '') ? toLower('${privateDnsZone}') : 'defaultforvalidation'

var commonTags = {
  Location: 'global'
  CreatedDate: createdDate
  Environment: environment
}
var tags = union(loadJsonContent('../../../../common/default-tags.json'), commonTags)

var dnsTags = {
  Name: privateDnsZoneName
  Purpose: 'Container App Env Private DNS Zone'
}
var dnsVnetLinksTags = {
  Name: vnet.name
  Purpose: 'Container App Env Private DNS Zone VNet Link'
}

module privateDnsZoneModule 'br/SharedDefraRegistry:network.private-dns-zone:0.5.2' = {
  name: 'caenv-private-dns-zone-${deploymentDate}'
  params: {
   name: privateDnsZoneName  
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

