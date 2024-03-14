using './container-apps-env.bicep'

param containerAppEnv = {
  name: '#{{ containerAppEnv }}'
  workloadProfiles: [
    {
      workloadProfileType: 'Consumption'
    }
  ]
}
param containerApp = {
  name: '#{{ portalWebContainerAppName }}'
  hostName: '#{{ portalWebHostName }}'
}
param workspace = {
  name: '#{{ logAnalyticsWorkspace }}'
  resourceGroup: '#{{ ssvSharedResourceGroup }}'
  subscriptionId: '#{{ SubscriptionId }}'
}

param subnet = {
  name: '#{{ containerAppSubnet }}'
  resourceGroup: '#{{ ssvVirtualNetworkResourceGroup }}'
  vnetName: '#{{ ssvVirtualNetworkName }}'
}

param keyvaultName = '#{{ portalAppKeyVaultName }}'

param ssvPlatformKeyVaultName = '#{{ ssvPlatformKeyVaultName }}'

param ssvPlatformKeyVaultRG = '#{{ ssvSharedResourceGroup }}'

param environment = '#{{ environment }}'

param location = '#{{ location }}'

param portalEntraApp = {
  tenantIdSecretName: '#{{ portalApplicationClientTenantName }}'
  tenantIdSecretValue: '#{{ tenantId }}'
}

param internal = true 

param frontDoorEndpointURL = '#{{ portalWebAppURLKVSecretName }}'
