@description('Required. The parameter object for the virtual network. The object must contain the name,resourceGroup and subnetPrivateEndpoints values.')
param vnet object

//@description('Require. The parameter object of LogAnalytics Workspace.  The object must contain the resourceGroup and name of the log analytics workspace.')
//param logAnalyticsWorkspace object

@description('Required. The parameter object for servicebus. The object must contain the namespaceName,namespacePrivateEndpointName and skuName values.')
param serviceBus object

@description('Required. The Azure region where the resources will be deployed.')
param location string = resourceGroup().location

@description('Required. Environment name.')
param environment string

@description('Required. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Required. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}
var tags = union(loadJsonContent('../default-tags.json'), customTags)

var serviceBusTags = {
  Name: serviceBus.namespaceName
  Purpose: 'Service Bus Namespace'
  Tier: 'Shared'
}

var serviceBusPrivateEndpointTags = {
  Name: serviceBus.namespacePrivateEndpointName
  Purpose: 'Service Bus Namespace private endpoint'
  Tier: 'Shared'
}

resource vnetResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  scope: subscription()
  name: vnet.resourceGroup
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-02-01' existing = {
  scope: vnetResourceGroup
  name: vnet.name
  resource privateEndpointSubnet 'subnets@2023-02-01' existing = {
    name: vnet.subnetPrivateEndpoints
  }
}

//resource logAnalyticsWorkspaceResource 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
//  scope: resourceGroup(logAnalyticsWorkspace.resourceGroup)
//  name: logAnalyticsWorkspace.name
//}

module serviceBusResource 'br/SharedDefraRegistry:service-bus.namespaces:0.5.7' = {
  name: 'service-bus-${deploymentDate}'
  params: {
    name: serviceBus.namespaceName
    skuName: serviceBus.skuName
    diagnosticWorkspaceId: '' //logAnalyticsWorkspaceResource.id
    networkRuleSets: {
      publicNetworkAccess: 'Disabled'
    }
    privateEndpoints: [
      {
        name: serviceBus.namespacePrivateEndpointName
        service: 'namespace'
        subnetResourceId: virtualNetwork::privateEndpointSubnet.id
        tags: union(tags, serviceBusPrivateEndpointTags)
      }
    ]
    tags: union(tags, serviceBusTags)
  }
}
