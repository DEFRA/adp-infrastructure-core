using 'open-ai-zone.bicep'

param vnet = {
  name: '#{{ virtualNetworkName }}'
  resourceGroup: '#{{ virtualNetworkResourceGroup }}'
}

param privateDnsZonePrefix = '#{{ dnsResourceNamePrefix }}#{{ nc_resource_dnszone }}#{{ nc_instance_regionid }}03'

param location = '#{{ location }}'

param environment = '#{{ environment }}'
