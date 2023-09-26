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

@description('Required. Array of role assignment objects that contain the \'roleDefinitionIdOrName\' and \'principalId\' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
param roleAssignments array

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


