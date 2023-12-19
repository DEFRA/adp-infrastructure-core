using './key-vault.bicep'

param keyVault = {
  name: '#{{ ssvResourceNamePrefix }}#{{ nc_resource_keyvault }}#{{ nc_shared_instance_regionid }}02'
  privateEndpointName: '#{{ ssvResourceNamePrefix }}#{{ nc_resource_privateendpoint }}#{{ nc_instance_regionid }}02'
  skuName: 'premium'
  enableSoftDelete: '#{{ keyvaultEnableSoftDelete }}'
  enablePurgeProtection: '#{{ keyvaultEnablePurgeProtection }}'
  softDeleteRetentionInDays: '#{{ keyvaultSoftDeleteRetentionInDays }}'
}

param vnet = {
  name: '#{{ ssvVirtualNetworkName }}'
  resourceGroup: '#{{ ssvVirtualNetworkResourceGroup }}'
  subnetPrivateEndpoints: '#{{ networkResourceNamePrefix }}#{{ nc_resource_subnet }}#{{ nc_instance_regionid }}03'
}

param environment = '#{{ environment }}'

param location = '#{{ location }}'

param principalId = '#{{ ssvAppRegServicePrincipalId }}'
