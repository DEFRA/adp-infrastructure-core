@description('Required. The parameter object for the virtual network. The object must contain the name,resourceGroup and subnetPrivateEndpoints values.')
param vnet object

@description('Required. The parameter object for appConfig. The object must contain the name and privateEndpointName values.')
param appConfig object = {
  name: 'SNDCDOINFAC2401'
  privateEndpointName: 'SNDCDOINFPE2402'
}

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

var appConfigTags = {
  Name: appConfig.name
  Purpose: 'Service Bus Namespace'
  Tier: 'Shared'
}

var appConfigPrivateEndpointTags = {
  Name: appConfig.privateEndpointName
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


module appConfigResource 'br/SharedDefraRegistry:app-configuration.configuration-stores:0.3.6' = {
  name: 'app-config-${deploymentDate}'
  params: {
    name: appConfig.name
    createMode: 'Default'
    disableLocalAuth: true
    enablePurgeProtection: false
    privateEndpoints: [
      {
        name: appConfig.privateEndpointName
        service: 'configurationStores'
        subnetResourceId: virtualNetwork::privateEndpointSubnet.id
        tags: union(tags, appConfigPrivateEndpointTags)
      }
    ]
    softDeleteRetentionInDays: 1
    tags: union(tags, appConfigTags)
  }
}
