@description('Required. The parameter object for the virtual network. The object must contain the name,resourceGroup and subnetPrivateEndpoints values.')
param vnet object

@description('Required. The parameter object for eventHub. The object must contain the name and privateEndpointName values.')
param eventHub object

@description('Required. Environment name.')
param environment string

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

@description('Optional. The Azure region where the resources will be deployed.')
param location string = resourceGroup().location

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}
var tags = union(loadJsonContent('../../../common/default-tags.json'), customTags)

var eventHubTags = {
  Name: eventHub.name
  Purpose: 'ADP Core Event Hub'
  Tier: 'Shared'
}

var appConfigPrivateEndpointTags = {
  Name: eventHub.privateEndpointName
  Purpose: 'Event Hub private endpoint'
  Tier: 'Shared'
}

module eventHubResource 'br/SharedDefraRegistry:event-hub.namespace:0.5.18' = {
  name: 'event-hub-${deploymentDate}'
  params: {
    enableDefaultTelemetry: true
    name: eventHub.name
    skuName: 'Standard'
    location: location
    lock: {
      kind: 'CanNotDelete'
    }
    tags: union(tags, eventHubTags)
    privateEndpoints: [
      {
        name: eventHub.privateEndpointName
        service: 'namespace'
        subnetResourceId: resourceId(vnet.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnet.name, vnet.subnetPrivateEndpoints)
        tags: union(tags, appConfigPrivateEndpointTags)
      }
    ]
  }
}
