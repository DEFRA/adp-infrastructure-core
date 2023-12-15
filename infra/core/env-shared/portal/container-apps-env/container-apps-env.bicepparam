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
  name: '#{{ ssvResourceNamePrefix }}#{{ nc_resource_containerapps }}#{{ nc_shared_instance_regionid }}01'
  hostName: '#{{ ssvPortalHostName }}'
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

param keyvaultName = '#{{ ssvResourceNamePrefix }}#{{ nc_resource_keyvault }}#{{ nc_shared_instance_regionid }}02'

param ssvPlatformKeyVaultName = '#{{ ssvPlatformKeyVaultName }}'


param environment = '#{{ environment }}'

param location = '#{{ location }}'

param portalEntraApp = {
  tenantIdSecretName: '#{{ portalApplicationClientTenantName }}' 
  tenantIdSecretValue: '#{{ tenantId }}'
}
