using './containerapp-dns-zone.bicep'

param vnet = {
  name: '#{{ ssvVirtualNetworkName }}'
  resourceGroup: '#{{ ssvVirtualNetworkResourceGroup }}'
}

//Value of the privateDnsZone parameter is set to the output of the container-apps-env.bicep file
param privateDnsZone = az.getSecret('#{{ ssvSubscriptionId }}', '#{{ ssvSharedResourceGroup }}', '#{{ ssvPlatformKeyVaultName }}', '#{{ containerAppEnvURLKVSecretName }}')

param environment = '#{{ environment }}'
