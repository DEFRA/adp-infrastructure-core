using './key-vault.bicep'

param keyVault = {
  name: '#{{ infraResourceNamePrefix }}#{{ nc_resource_keyvault }}#{{ nc_instance_regionid }}02'
  privateEndpointName: '#{{ infraResourceNamePrefix }}#{{ nc_resource_privateendpoint }}#{{ nc_instance_regionid }}06'
  skuName: 'premium'
  enableSoftDelete: '#{{ keyvaultEnableSoftDelete }}'
  enablePurgeProtection: '#{{ keyvaultEnablePurgeProtection }}'
  softDeleteRetentionInDays: '#{{ keyvaultSoftDeleteRetentionInDays }}'
}

param vnet = {
  name: '#{{ virtualNetworkName }}'
  resourceGroup: '#{{ virtualNetworkResourceGroup }}'
  subnetPrivateEndpoints: '#{{ networkResourceNamePrefix }}#{{ nc_resource_subnet }}#{{ nc_instance_regionid }}98'
}

param environment = '#{{ environment }}'

param location = '#{{ location }}'

param keyvaultType = 'Platform'

param principalId = ''
