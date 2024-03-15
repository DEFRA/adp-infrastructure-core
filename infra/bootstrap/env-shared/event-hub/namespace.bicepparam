using './namespace.bicep'

param eventHubNamespace = {
  name: '#{{ ssvResourceNamePrefix }}#{{nc_resource_eventhub }}#{{nc_shared_instance_regionid }}01'
  privateEndpointName: '#{{ ssvResourceNamePrefix }}#{{nc_resource_privateendpoint }}#{{nc_shared_instance_regionid }}05'
  // eventHub1Name: '#{{ eventHub1Name }}'
  // eventHub2Name: '#{{ eventHub2Name }}'
}

param location = '#{{ location }}'

param environment = '#{{ environment }}'

param vnet = {
  name: '#{{ ssvVirtualNetworkName }}'
  resourceGroup: '#{{ ssvVirtualNetworkResourceGroup }}'
  subnetPrivateEndpoints: '#{{ networkResourceNamePrefix }}#{{ nc_resource_subnet }}#{{ nc_instance_regionid }}03'
}
