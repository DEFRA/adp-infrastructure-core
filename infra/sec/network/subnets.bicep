param secVnetName string
param appGwSubnet3401Name string
param appGwSubnet3401Range string

resource externalSubnets 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = {
  name: '${secVnetName}/${appGwSubnet3401Name}'
  properties: {
    addressPrefix: appGwSubnet3401Range
    networkSecurityGroup: {}
    serviceEndpoints: []
    routeTable: {}
  }
}
