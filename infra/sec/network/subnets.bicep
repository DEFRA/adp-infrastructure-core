param secVnetName string
param appGwSubnetName string
param appGwSubnetRange string
param networkSecurityGroup object

resource externalSubnets 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = {
  name: '${secVnetName}/${appGwSubnetName}'
  properties: {
    addressPrefix: appGwSubnetRange
    networkSecurityGroup: {
      id: resourceId(networkSecurityGroup.resourceGroup, 'Microsoft.Network/networkSecurityGroups', networkSecurityGroup.name)
    }
  }
}

