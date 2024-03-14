using './subnets.bicep'

param secVnetName = '#{{ secVirtualNetworkName }}'
param appGwSubnetName = '#{{ secAppGatewaySubnetName }}'
param appGwSubnetRange = '#{{ secappGwSubnetRange }}'
