using '../container-apps-env.bicep'

param containerAppEnv = {
  name: '#{{ ssvResourceNamePrefix }}#{{ nc_resource_containerappsenv }}#{{ nc_shared_instance_regionid }}02'
  workloadProfiles: [
    {
      workloadProfileType: 'Consumption'
    }
  ]
}
param containerApp = {
  name: '#{{ ssvResourceNamePrefix }}#{{ nc_resource_containerapps }}#{{ nc_shared_instance_regionid }}02-portal-web'
  hostName: '#{{ ssvPortalHostName }}'
}
param workspace = {
  name: '#{{ logAnalyticsWorkspace }}'
  resourceGroup: '#{{ ssvSharedResourceGroup }}'
  subscriptionId: '#{{ SubscriptionId }}'
}

param subnet = {
  name: '#{{ networkResourceNamePrefix }}#{{ nc_resource_subnet }}#{{ nc_instance_regionid }}04'
  resourceGroup: '#{{ ssvVirtualNetworkResourceGroup }}'
  vnetName: '#{{ ssvVirtualNetworkName }}'
}

param keyvaultName = '#{{ ssvResourceNamePrefix }}#{{ nc_resource_keyvault }}#{{ nc_shared_instance_regionid }}03'

param ssvPlatformKeyVaultName = '#{{ ssvPlatformKeyVaultName }}'

param ssvPlatformKeyVaultRG = '#{{ ssvSharedResourceGroup }}'

param environment = '#{{ environment }}'

param location = '#{{ location }}'

param portalEntraApp = {
  tenantIdSecretName: '#{{ portalApplicationClientTenantName }}'
  tenantIdSecretValue: '#{{ tenantId }}'
}

param internal = true 

param frontDoorEndpointURL = 'PORTAL-APP-2-DEFAULT-URL'
