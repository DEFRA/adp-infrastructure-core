using './namespace.bicep'

param eventHub = {
  name: '#{{ infraResourceNamePrefix }}#{{ nc_resource_eventhub }}#{{ nc_instance_regionid }}01'
  privateEndpointName: '#{{ infraResourceNamePrefix }}#{{ nc_resource_privateendpoint }}#{{ nc_instance_regionid }}07'
}

param location = '#{{ location }}'

param environment = '#{{ environment }}'

param vnet = {
  name: '#{{ virtualNetworkName }}'
  resourceGroup: '#{{ virtualNetworkResourceGroup }}'
  subnetPrivateEndpoints: '#{{ networkResourceNamePrefix }}#{{ nc_resource_subnet }}#{{ nc_instance_regionid }}98'
}
