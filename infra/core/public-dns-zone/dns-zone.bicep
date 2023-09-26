
@description('Required. The name of the public DNS zone.')
param publicDnsZoneName string

@allowed([
  'UKSouth'
])
@description('Required. The Azure region where the resources will be deployed.')
param location string

@description('Required. Environment name.')
param environment string

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

var commonTags = {
  Name: publicDnsZoneName
  Location: location
  CreatedDate: createdDate
  Environment: environment
  Purpose: 'ADP Public DNS Zone'
}
var tags = union(loadJsonContent('../../common/default-tags.json'), commonTags)

resource publicDnsZone 'Microsoft.Network/dnsZones@2023-07-01-preview' = {
  name: publicDnsZoneName
  location: location
  tags: tags
  properties: {
    zoneType: 'Public'  
  }
}
