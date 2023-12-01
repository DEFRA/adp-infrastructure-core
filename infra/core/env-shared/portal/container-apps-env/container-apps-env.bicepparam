using './container-apps-env.bicep'

param containerAppEnv = {
  name: '#{{ ssvResourceNamePrefix }}#{{ nc_resource_containerappsenv }}#{{ nc_shared_instance_regionid }}01'    
  workloadProfiles: [
    {
      workloadProfileType: 'Consumption'
    }
  ]
}
param containerApp = {
  name: 'portal' 
  managedIdentityName: '#{{ infraResourceNamePrefix }}#{{ nc_resource_managedidentity }}#{{ nc_instance_regionid }}01-adp-portal'
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

param keyvaultName = '#{{ ssvResourceNamePrefix }}#{{ nc_resource_keyvault }}#{{ nc_shared_instance_regionid }}03'

param environment = '#{{ environment }}'

param location = '#{{ location }}'
