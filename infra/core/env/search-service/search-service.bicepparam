using './search-service.bicep'

param searchService = {
  name: '#{{ infraResourceNamePrefix }}#{{ nc_resource_search }}#{{ nc_instance_regionid }}01'
  skuName: '#{{ searchServiceSkuName }}'
  replicaCount: '#{{ searchServiceReplicaCount }}'
  privateEndpointName: '#{{ infraResourceNamePrefix }}#{{ nc_resource_privateendpoint }}#{{ nc_instance_regionid }}11'  
  openAiName: '#{{ infraResourceNamePrefix }}#{{ nc_resource_openai }}#{{ nc_instance_regionid }}01'
}

param managedIdentityName = '#{{ infraResourceNamePrefix }}#{{ nc_resource_managedidentity }}#{{ nc_instance_regionid }}01-search-service'

param location = '#{{ location }}'

param environment = '#{{ environment }}'

param searchServiceUserGroupId = '#{{ searchServiceUserGroupId }}'

param vnet = {
  name: '#{{ virtualNetworkName }}'
  resourceGroup: '#{{ virtualNetworkResourceGroup }}'
  subnetPrivateEndpoints: '#{{ networkResourceNamePrefix }}#{{ nc_resource_subnet }}#{{ nc_instance_regionid }}98'
}

param monitoringWorkspace = {
  name: '#{{ logAnalyticsWorkspace }}'
  resourceGroup: '#{{ servicesResourceGroup }}'
}

param privateLinkServiceConnectionExists = '#{{ privateLinkServiceConnectionExists }}'

param resourceLockEnabled = #{{ resourceLockEnabled }}
