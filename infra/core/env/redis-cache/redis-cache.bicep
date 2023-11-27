@description('Required. The parameter object for the virtual network. The object must contain the name,resourceGroup and rediscachesubnet values.')
param vnet object

@description('Required. The parameter object for redis cache. The object must contain the name, skuName and capacity  values.')
param redisCache object

@description('Optional. The Azure region where the resources will be deployed.')
param location string = resourceGroup().location

@description('Required. Environment name.')
param environment string

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

@description('Optional. Object array, with propterties Name, addressprefix in cidr format')
param firewallRules array = []

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}
var tags = union(loadJsonContent('../../common/default-tags.json'), customTags)

var redisCacheTags = {
  Name: redisCache.name 
  Purpose: 'Redis Cache'
  Tier: 'Shared'
}

module redisCacheResource 'br/SharedDefraRegistry:cache.redis:0.5.10' = {
  name: 'redis-cache-${deploymentDate}'
  params: {
    name: redisCache.name
    skuName: redisCache.skuName
    capacity: int(redisCache.capacity)
    location: location
    lock: 'CanNotDelete'
    subnetId: resourceId(vnet.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnet.name, vnet.rediscachesubnet)
    tags: union(tags, redisCacheTags)
  }
}

module redisCacheFirewallRules '.bicep/firewall-rules.bicep' = {
  name: 'redis-cache-firewall-rules-${deploymentDate}'
  dependsOn: [
    redisCacheResource
  ]
  params: {
    redisCacheName: redisCache.name
    redisCacheSkuName: redisCache.skuName
    firewallRules: firewallRules
  }
}
