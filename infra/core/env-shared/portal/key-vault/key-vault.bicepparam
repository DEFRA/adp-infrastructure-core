using './key-vault.bicep'

param keyVault = {
  name: '#{{ ssvInfraKeyVault }}'
  privateEndpointName: '#{{ ssvInfraKVPvtEndpointName }}'
  skuName: 'premium'
  enableSoftDelete: '#{{ keyvaultEnableSoftDelete }}'
  enablePurgeProtection: '#{{ keyvaultEnablePurgeProtection }}'
  softDeleteRetentionInDays: '#{{ keyvaultSoftDeleteRetentionInDays }}'
}

param vnet = {
  name: '#{{ ssvVirtualNetworkName }}'
  resourceGroup: '#{{ ssvVirtualNetworkResourceGroup }}'
  subnetPrivateEndpoints: '#{{ ssvPrivateEndpointSubnet }}'
}

param environment = '#{{ environment }}'

param location = '#{{ location }}'

param principalId = '#{{ ssvAppRegServicePrincipalId }}'
