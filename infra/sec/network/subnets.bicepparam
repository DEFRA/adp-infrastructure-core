using './subnets.bicep'

param secVnetName = '#{{ secVirtualNetworkName }}'
param appGwSubnetName = '#{{ secAppGatewaySubnetName }}'
param appGwSubnetRange = '#{{ secappGwSubnetRange }}'

param networkSecurityGroup = {
  name: 'SEC#{{ projectName }}#{{ environment }}#{{ nc_resource_nsg }}140#{{ environmentId }}'
  resourceGroup: '#{{ secInfraResourceGroup }}'
}
