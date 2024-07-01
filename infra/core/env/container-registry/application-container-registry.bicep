@description('Required. The parameter object for the virtual network. The object must contain the name,skuName,resourceGroup and subnetPrivateEndpoints values.')
param vnet object

@description('Required. The parameter object for container registry. The object must contain the name, enableSoftDelete, enablePurgeProtection and softDeleteRetentionInDays values.')
param containerRegistry object

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. Environment name.')
param environment string

@description('Optional. Enable a single data endpoint per region for serving data. Not relevant in case of disabled public access. Note, requires the \'acrSku\' to be \'Premium\'.')
param dataEndpointEnabled bool = false

@description('Required. Boolean value to enable resource lock.')
param resourceLockEnabled bool

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}

var defaultTags = union(json(loadTextContent('../../../common/default-tags.json')), customTags)

var containerRegistryTags = {
  Name: containerRegistry.name
  Purpose: 'Container Registry'
  Tier: 'Shared'
}

var containerRegistryPrivateEndpointTags = {
  Name: containerRegistry.privateEndpointName
  Purpose: 'Container Registry private endpoint'
  Tier: 'Shared'
}

module registry 'br/SharedDefraRegistry:container-registry.registry:0.5.5' = {
  name: 'app-containerregistry-${deploymentDate}'
  params: {
    name: containerRegistry.name
    acrSku: containerRegistry.acrSku
    lock: resourceLockEnabled ? 'CanNotDelete' : null
    retentionPolicyDays: int(containerRegistry.retentionPolicyDays)
    softDeletePolicyDays: int(containerRegistry.softDeletePolicyDays)
    tags: union(defaultTags, containerRegistryTags)
    dataEndpointEnabled: dataEndpointEnabled
    publicNetworkAccess: 'Disabled'
    privateEndpoints: [
      {
        name: containerRegistry.privateEndpointName
        service: 'registry'
        subnetResourceId: resourceId(vnet.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnet.name, vnet.subnetPrivateEndpoints)
        tags: union(defaultTags, containerRegistryPrivateEndpointTags)
      }
    ]
  }
}
