using './configuration-store.bicep'

param appConfig = {
  name: '#{{ infraResourceNamePrefix }}#{{ nc_resource_appconfiguration }}#{{ nc_instance_regionid }}01'
  privateEndpointName: '#{{ infraResourceNamePrefix }}#{{ nc_resource_privateendpoint }}#{{ nc_instance_regionid }}02'
  softDeleteRetentionInDays: '#{{ appConfigurationSoftDeleteRetentionInDays }}'
  enablePurgeProtection: '#{{ appConfigurationEnablePurgeProtection }}'
}

param sku = '#{{ appConfigurationSku }}'

param vnet = {
  name: '#{{ virtualNetworkName }}'
  resourceGroup: '#{{ virtualNetworkResourceGroup }}'
  subnetPrivateEndpoints: '#{{ networkResourceNamePrefix }}#{{ nc_resource_subnet }}#{{ nc_instance_regionid }}98'
}

param location = '#{{ location }}'

param environment = '#{{ environment }}'

param principalId = az.getSecret('#{{ ssvSubscriptionId }}', '#{{ ssvSharedResourceGroup }}', '#{{ ssvPlatformKeyVaultName }}', '#{{ tier2ApplicationSPObjectIdSecretName }}')

param platformTeamGroupId = '#{{ aksAADProfileAdminGroupObjectId }}'
