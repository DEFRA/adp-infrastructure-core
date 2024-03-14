param secVnetName string
param appGwSubnetName string
param appGwSubnetRange string

resource externalSubnets 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = {
  name: '${secVnetName}/${appGwSubnetName}'
  properties: {
    addressPrefix: appGwSubnetRange
    networkSecurityGroup: {}
    serviceEndpoints: []
    routeTable: {}
  }
}

