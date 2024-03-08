using './storage.bicep'

param location = '#{{ location }}'

param environment = '#{{ environment }}'

param vnet = {
  name: '#{{ virtualNetworkName }}'
  resourceGroup: '#{{ virtualNetworkResourceGroup }}'
  subnetPrivateEndpoints: '#{{ networkResourceNamePrefix }}#{{ nc_resource_subnet }}#{{ nc_instance_regionid }}98'
}

param storageAccount = {
  name: '#{{ infraResourceNamePrefix }}#{{ nc_resource_storageaccount }}#{{ nc_instance_regionid }}02'
  privateEndpointName: '#{{ infraResourceNamePrefix }}#{{ nc_resource_privateendpoint }}#{{ nc_instance_regionid }}08'
  skuName: 'Standard_ZRS'
  fileShareName: 'function-content-share'
  kind: 'StorageV2'
}
