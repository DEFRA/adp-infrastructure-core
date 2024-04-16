using './namespace.bicep'

param eventHubNamespace = {
  name: '#{{ infraResourceNamePrefix }}#{{nc_resource_eventhub }}#{{nc_shared_instance_regionid }}01'
  privateEndpointName: '#{{ infraResourceNamePrefix }}#{{nc_resource_privateendpoint }}#{{nc_shared_instance_regionid }}01'
}

param location = '#{{ location }}'

param environment = '#{{ environment }}'

param vnet = {
  name: '#{{ ssvVirtualNetworkName }}'
  resourceGroup: '#{{ ssvVirtualNetworkResourceGroup }}'
  subnetPrivateEndpoints: '#{{ networkResourceNamePrefix }}#{{ nc_resource_subnet }}#{{ nc_instance_regionid }}01'
}
