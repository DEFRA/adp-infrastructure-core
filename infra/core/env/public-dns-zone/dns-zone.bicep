
@description('Required. The name of the public DNS zone.')
param publicDnsZoneName string

@allowed([
  'global'
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
  Name: publicDnsZoneName
  Location: location
  CreatedDate: createdDate
  Environment: environment
  Purpose: 'ADP Public DNS Zone'
}
var tags = union(loadJsonContent('../../common/default-tags.json'), commonTags)

module publicDnsZone 'br/SharedDefraRegistry:network.dns-zone:0.5.2' = {
  name: 'public-dns-zone-${deploymentDate}'
  params: {
    name: publicDnsZoneName
    location: location
    tags: tags
    enableDefaultTelemetry: true
    lock: 'CanNotDelete'
  }
}
