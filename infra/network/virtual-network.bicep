@description('The VNET Infra object.')
param vnet object


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
var tags = union(loadJsonContent('../default-tags.json'), commonTags)

module virtualNetwork 'br/SharedDefraRegistry:network.virtual-networks:0.4.7' = {
  name: 'virtual-network-${deploymentDate}'
  params: {
    name: vnet.name
    location: location
    lock: 'CanNotDelete'
    tags: tags
    enableDefaultTelemetry: true
    addressPrefixes: split(vnet.addressPrefixes, ';')
    dnsServers: split(vnet.dnsServers, ';')
    subnets: subnets
  }
}
