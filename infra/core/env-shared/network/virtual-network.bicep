@description('Required. The VNET Infra object.')
param vnet object

@description('Required. The subnets object.')
param subnets array

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

var commonTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
  Purpose: 'ADP-VIRTUAL-NETWORK'
}
var tags = union(loadJsonContent('../../../common/default-tags.json'), commonTags)

//Removed lock to deploy postgress db. VNet cannot be deleted when there are child resources
module virtualNetwork 'br/SharedDefraRegistry:network.virtual-network:0.4.2' = {
  name: 'virtual-network-${deploymentDate}'
  params: {
    name: vnet.name
    location: location
    tags: tags
    enableDefaultTelemetry: true
    addressPrefixes: vnet.addressPrefixes
    dnsServers: vnet.dnsServers
    subnets: subnets
  }
}
