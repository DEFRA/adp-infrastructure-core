using '../flexible-server-zone.bicep'

param vnet = {
  name: '#{{ ssvVirtualNetworkName }}'
  resourceGroup: '#{{ ssvVirtualNetworkResourceGroup }}'
}

param privateDnsZonePrefix = '#{{ dnsResourceNamePrefix }}#{{ nc_resource_dnszone }}#{{ nc_instance_regionid }}02'

param environment = '#{{ environment }}'
