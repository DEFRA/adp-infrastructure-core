@description('Required. The parameter object for the virtual network. The object must contain the name,resourceGroup and subnetPrivateEndpoints values.')
param vnet object

@description('Required. The parameter object for eventHub. The object must contain the name and privateEndpointName values.')
param eventHubNamespace object

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

var eventHubNamespaceTags = {
  Name: eventHubNamespace.name
  Purpose: 'ADP Core Event Hub'
  Tier: 'Shared'
}

var eventHubNamespacePrivateEndpointTags = {
  Name: eventHubNamespace.privateEndpointName
  Purpose: 'Event Hub private endpoint'
  Tier: 'Shared'
}

module eventHubNamespaceResource 'br/SharedDefraRegistry:event-hub.namespace:0.5.18' = {
  name: 'event-hub-namespace-${deploymentDate}'
  params: {
    enableDefaultTelemetry: true
    name: eventHubNamespace.name
    skuName: 'Standard'
    location: location
    lock: {
      kind: 'CanNotDelete'
    }
    tags: union(tags, eventHubNamespaceTags)
    networkRuleSets: {
      defaultAction: 'Deny'
      trustedServiceAccessEnabled: true
      publicNetworkAccess: 'Disabled'
    }
    privateEndpoints: [
      {
        name: eventHubNamespace.privateEndpointName
        service: 'namespace'
        subnetResourceId: resourceId(vnet.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnet.name, vnet.subnetPrivateEndpoints)
        tags: union(tags, eventHubNamespacePrivateEndpointTags)
      }
    ]
    disableLocalAuth: false
    /*eventhubs: [
      {
        name: 'flux-events-${eventHubNamespace.eventHub1Name}'
        authorizationRules: [
          {
            name: 'FluxSendAccess'
            rights: [
              'Send'
            ]
          }
          {
            name: 'FunctionListenAccess'
            rights: [
              'Listen'
            ]
          }
        ]
      }
      {
        name: 'flux-events-${eventHubNamespace.eventHub2Name}'
        authorizationRules: [
          {
            name: 'FluxSendAccess'
            rights: [
              'Send'
            ]
          }
          {
            name: 'FunctionListenAccess'
            rights: [
              'Listen'
            ]
          }
        ]
      }
    ]*/
  }
}
