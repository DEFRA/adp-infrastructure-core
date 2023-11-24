using './virtual-network.bicep'

param vnet = {
  name: '#{{ ssvVirtualNetworkName }}'
  addressPrefixes: '#{{ vnet1AddressPrefixes }}'
  dnsServers: '#{{ dnsServers }}'
}

param subnets = [
  {
    name: '#{{ networkResourceNamePrefix }}#{{ nc_resource_subnet }}#{{ nc_instance_regionid }}01'
    addressPrefix: '#{{ subnet1AddressPrefix }}'
    serviceEndpoints: []
    delegations: [
      {
        name: 'Microsoft.App.environments'
        properties: {
          serviceName: 'Microsoft.App/environments'
        }
      }
    ]
    routeTableId: '/subscriptions/#{{ subscriptionId }}/resourceGroups/#{{ ssvVirtualNetworkResourceGroup }}/providers/Microsoft.Network/routeTables/UDR-Spoke-Route-From-#{{ ssvVirtualNetworkName }}'
    networkSecurityGroupId: '/subscriptions/#{{ subscriptionId }}/resourceGroups/#{{ ssvVirtualNetworkResourceGroup }}/providers/Microsoft.Network/networkSecurityGroups/#{{ networkResourceNamePrefix }}#{{ nc_resource_nsg }}#{{ nc_instance_regionid }}01'
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
  {
    name: '#{{ networkResourceNamePrefix }}#{{ nc_resource_subnet }}#{{ nc_instance_regionid }}02'
    addressPrefix: '#{{ subnet2AddressPrefix }}'
    serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
      }
    ]
    delegations: [
      {
        name: 'Microsoft.DBforPostgreSQL.flexibleServers'
        properties: {
          serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
        }
      }
    ]
    routeTableId: '/subscriptions/#{{ subscriptionId }}/resourceGroups/#{{ ssvVirtualNetworkResourceGroup }}/providers/Microsoft.Network/routeTables/UDR-Spoke-Route-From-#{{ ssvVirtualNetworkName }}'
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
  {
    name: '#{{ networkResourceNamePrefix }}#{{ nc_resource_subnet }}#{{ nc_instance_regionid }}03'
    addressPrefix: '#{{ subnet3AddressPrefix }}'
    serviceEndpoints: [
      {
        service: 'Microsoft.ContainerRegistry'
      }
      {
        service: 'Microsoft.Storage'
      }
      {
        service: 'Microsoft.EventHub'
      }
      {
        service: 'Microsoft.ServiceBus'
      }
      {
        service: 'Microsoft.KeyVault'
      }
    ]
    routeTableId: '/subscriptions/#{{ subscriptionId }}/resourceGroups/#{{ ssvVirtualNetworkResourceGroup }}/providers/Microsoft.Network/routeTables/UDR-Spoke-Route-From-#{{ ssvVirtualNetworkName }}'
    networkSecurityGroupId: '/subscriptions/#{{ subscriptionId }}/resourceGroups/#{{ ssvVirtualNetworkResourceGroup }}/providers/Microsoft.Network/networkSecurityGroups/#{{ networkResourceNamePrefix }}#{{ nc_resource_nsg }}#{{ nc_instance_regionid }}01'
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Disabled'
  }
]

param location = '#{{ location }}'

param environment = '#{{ environment }}'
