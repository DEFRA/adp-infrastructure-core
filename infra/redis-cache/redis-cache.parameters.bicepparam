using 'redis-cache.bicep'

param redisCache = {
  name: '#{{ infraResourceNamePrefix }}#{{ nc_resource_redis }}#{{ nc_instance_regionid }}01'
  skuName: '#{{ redisCacheSkuName }}'
  Family: 'P'
  capacity: '1'
}

param vnet = {
  name: '#{{ virtualNetworkName }}'
  resourceGroup: '#{{ virtualNetworkResourceGroup }}'
  rediscachesubnet: '#{{ networkResourceNamePrefix }}#{{ nc_resource_subnet }}#{{ nc_instance_regionid }}04'
}

param location = '#{{ location }}'

param environment = '#{{ environment }}'

param firewallRules = [
  //AKS Cluster 
  {
    name: '#{{ infraResourceNamePrefix }}#{{ nc_resource_kubernetesservice }}#{{ nc_instance_regionid }}01'
    addressprefix: '#{{ subnet1AddressPrefix }}' 
  }
]
