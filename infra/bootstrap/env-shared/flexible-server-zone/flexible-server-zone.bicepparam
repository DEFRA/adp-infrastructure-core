using './flexible-server-zone.bicep'

param vnet = {
  name: '#{{ ssvVirtualNetworkName }}'
  resourceGroup: '#{{ ssvVirtualNetworkResourceGroup }}'
}

param privateDnsZone = '#{{ postgreSqlPvtDnsZone }}'

param environment = '#{{ environment }}'

param resourceLockEnabled = #{{ resourceLockEnabled }}
