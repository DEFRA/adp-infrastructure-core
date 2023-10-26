@description('Required. The parameter object for the virtual network. The object must contain the name,resourceGroup and subnetPrivateEndpoints values.')
param vnet object

@description('Required. The parameter object for appConfig. The object must contain the name, privateEndpointName, softDeleteRetentionInDays and enablePurgeProtection values.')
param appConfig object

@allowed([
  'Free'
  'Standard'
])
@description('Optional. Pricing tier of App Configuration.')
param sku string = 'Standard'

@description('Optional. The Azure region where the resources will be deployed.')
param location string = resourceGroup().location

@description('Required. Environment name.')
param environment string

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

@description('Required. principalId of service connection')
@secure()
param principalId string

// @description('Optional. Key-Value pair to be added to the Configuration Store')
// param keyValues array

var roleAssignments = [
  {
    roleDefinitionIdOrName: 'App Configuration Data Owner'
    description: 'App Configuration Data Owner Role Assignment'
    principalIds: [
      principalId
    ]
    principalType: 'ServicePrincipal'
  }
]

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}
var tags = union(loadJsonContent('../../common/default-tags.json'), customTags)

var appConfigTags = {
  Name: appConfig.name
  Purpose: 'App Configuration'
  Tier: 'Shared'
}

var appConfigPrivateEndpointTags = {
  Name: appConfig.privateEndpointName
  Purpose: 'App Configuration private endpoint'
  Tier: 'Shared'
}

module appConfigResource 'br/SharedDefraRegistry:app-configuration.configuration-store:0.3.3' = {
  name: 'app-config-${deploymentDate}'
  params: {
    name: appConfig.name
    sku: sku
    disableLocalAuth: true
    softDeleteRetentionInDays: int(appConfig.softDeleteRetentionInDays)
    enablePurgeProtection: bool(appConfig.enablePurgeProtection)
    publicNetworkAccess: 'Disabled'
    privateEndpoints: [
      {
        name: appConfig.privateEndpointName
        service: 'configurationStores'
        subnetResourceId: resourceId(vnet.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnet.name, vnet.subnetPrivateEndpoints)
        tags: union(tags, appConfigPrivateEndpointTags)
      }
    ]
    tags: union(tags, appConfigTags)
    roleAssignments: roleAssignments
  }
}
