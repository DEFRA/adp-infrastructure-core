@description('Required. The Route Table object.')
param routeTable object
@allowed([
  'UKSouth'
])
@description('Required. The Azure region where the resources will be deployed.')
param location string
@description('Required. Environment name.')
param environment string
@description('Required. Boolean value to enable resource lock.')
param resourceLockEnabled bool
@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')
@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

var commonTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
  Purpose: 'ADP-ROUTE-TABLE'
}
var tags = union(loadJsonContent('../default-tags.json'), commonTags)

module route 'br/SharedDefraRegistry:network.route-table:0.4.2' = {
  name: 'route-table-${deploymentDate}'
  params: {
    name: routeTable.name
    lock: resourceLockEnabled ? 'CanNotDelete' : null
    location: location
    tags: tags
    disableBgpRoutePropagation: true
    routes: [
      {
        name: 'Default'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: routeTable.virtualApplicanceIp
        }
      }
    ]
  }
}
