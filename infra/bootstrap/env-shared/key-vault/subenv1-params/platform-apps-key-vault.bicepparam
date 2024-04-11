using '../platform-apps-key-vault.bicep'

param keyVault = {
  name: '#{{ subEnvironment1KeyVault }}'
  privateEndpointName: '#{{ subEnvironment1KVPvtEndpointName }}'
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

param platformUserGroupId = '#{{ aksAADProfileAdminGroupObjectId }}'
