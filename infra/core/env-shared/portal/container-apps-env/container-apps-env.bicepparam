using './container-apps-env.bicep'

param containerAppEnv = {
  name: '#{{ ssvResourceNamePrefix }}#{{ nc_resource_containerappsenv }}#{{ nc_shared_instance_regionid }}03'    
  skuName: 'Consumption'
  workloadProfiles: [
    {
      workloadProfileType: 'D4'
      name: 'CAW3401'
      minimumCount: 0
      maximumCount: 3
    }
  ]
}
param containerApp = {
  name: '#{{ ssvResourceNamePrefix }}#{{ nc_resource_containerapps }}#{{ nc_shared_instance_regionid }}03' 
}
param workspace = {
  name: '#{{ logAnalyticsWorkspace }}'
  resourceGroup: '#{{ ssvSharedResourceGroup }}'
  subscriptionId: '#{{ SubscriptionId }}'
}

param subnet = {
  name: '#{{ networkResourceNamePrefix }}#{{ nc_resource_subnet }}#{{ nc_instance_regionid }}01'
  resourceGroup: '#{{ ssvVirtualNetworkResourceGroup }}'
  vnetName: '#{{ ssvVirtualNetworkName }}'
}

// param privateLink = {
//   name: 'capp-loadbalancer-pls'
//   visibility: {}
// }

// param privateDnsZonePrefix = '#{{ dnsResourceNamePrefix }}#{{ nc_resource_dnszone }}#{{ nc_instance_regionid }}01'

param environment = '#{{ environment }}'

param location = '#{{ location }}'
