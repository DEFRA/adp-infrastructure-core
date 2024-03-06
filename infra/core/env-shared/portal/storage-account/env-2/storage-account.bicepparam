using '../storage-account.bicep'

param storageAccount = {
  name: '#{{ ssvResourceNamePrefix }}#{{ nc_resource_storageaccount }}#{{ nc_instance_regionid }}02'
  privateEndpointName: '#{{ ssvResourceNamePrefix }}#{{ nc_resource_privateendpoint }}#{{ nc_instance_regionid }}03'
  skuName: 'Standard_ZRS'
  containerName: 'adp-wiki-techdocs'
}

param vnet = {
  name: '#{{ ssvVirtualNetworkName }}'
  resourceGroup: '#{{ ssvVirtualNetworkResourceGroup }}'
  subnetPrivateEndpoints: '#{{ networkResourceNamePrefix }}#{{ nc_resource_subnet }}#{{ nc_instance_regionid }}03'
}

param keyvaultName = '#{{ ssvResourceNamePrefix }}#{{ nc_resource_keyvault }}#{{ nc_shared_instance_regionid }}03'

param environment = '#{{ environment }}'

param location = '#{{ location }}'
