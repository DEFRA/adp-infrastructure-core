@description('Required. The object of the Container App Env.')
param containerAppEnv object

@description('Required. The parameter object for the virtual network. The object must contain the name and resourceGroup values.')
param vnet object

@description('Required. Environment name.')
param environment string

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

var commonTags = {
  Location: 'global'
  CreatedDate: createdDate
  Environment: environment
}
var tags = union(loadJsonContent('../../../common/default-tags.json'), commonTags)

var dnsTags = {
  Name: managedEnvironment.properties.defaultDomain
  Purpose: 'Container App Env Private DNS Zone'
}
var dnsVnetLinksTags = {
  Name: vnet.name
  Purpose: 'Container App Env Private DNS Zone VNet Link'
}

resource managedEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' existing = {
  name: containerAppEnv.name
  scope: resourceGroup(containerAppEnv.resourceGroup)
}

module privateDnsZoneModule 'br/SharedDefraRegistry:network.private-dns-zone:0.5.2' = {
  name: 'caenv-private-dns-zone-${deploymentDate}'
  params: {
    name: managedEnvironment.properties.defaultDomain
    tags: union(tags, dnsTags)
    virtualNetworkLinks: [
      {
        name: vnet.name
        virtualNetworkResourceId: resourceId(vnet.resourceGroup, 'Microsoft.Network/virtualNetworks', vnet.name)
        registrationEnabled: false
        tags: union(tags, dnsVnetLinksTags)
      }
    ]
    a: [
      {
        name: '*'
        ttl: 3600
        aRecords: [
          {
            ipv4Address: managedEnvironment.properties.staticIp
          }
        ]
      }
    ]
  }
}
