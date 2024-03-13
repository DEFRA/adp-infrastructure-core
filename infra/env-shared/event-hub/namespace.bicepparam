using './namespace.bicep'

param eventHub = {
  name: '#{{ eventHubName }}'
  privateEndpointName: '#{{ eventHubPrivateEndpointName }}'
}

param location = '#{{ location }}'

param environment = '#{{ environment }}'

param vnet = {
  name: '#{{ ssvVirtualNetworkName }}'
  resourceGroup: '#{{ ssvVirtualNetworkResourceGroup }}'
  subnetPrivateEndpoints: '#{{ networkResourceNamePrefix }}#{{ nc_resource_subnet }}#{{ nc_instance_regionid }}03'
}
