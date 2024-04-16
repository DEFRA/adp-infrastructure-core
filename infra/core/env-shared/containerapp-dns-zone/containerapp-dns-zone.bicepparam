using './containerapp-dns-zone.bicep'

param containerAppEnv = {
  name: '#{{ containerAppEnv }}'
  resourceGroup: '#{{ ssvInfraResourceGroup }}'
}

param vnet = {
  name: '#{{ ssvVirtualNetworkName }}'
  resourceGroup: '#{{ ssvVirtualNetworkResourceGroup }}'
}


param environment = '#{{ environment }}'
