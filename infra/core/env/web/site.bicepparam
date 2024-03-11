using './site.bicep'

param location = '#{{ location }}'

param environment = '#{{ environment }}'

param vnet = {
  name: '#{{ virtualNetworkName }}'
  resourceGroup: '#{{ virtualNetworkResourceGroup }}'
  subnetFunctionApp: '#{{ networkResourceNamePrefix }}#{{ nc_resource_subnet }}#{{ nc_instance_regionid }}94'
  subnetPrivateEndpoints: '#{{ networkResourceNamePrefix }}#{{ nc_resource_subnet }}#{{ nc_instance_regionid }}98'
}

param storageAccount = {
  name: '#{{ infraResourceNamePrefix }}#{{ nc_resource_storageaccount }}#{{ nc_instance_regionid }}02'
  fileShareName: 'function-content-share'
}

param appService = {
  name: '#{{ infraResourceNamePrefix }}FA#{{ nc_instance_regionid }}01'
  planName: '#{{ infraResourceNamePrefix }}SP#{{ nc_instance_regionid }}01'
  planSku: {
    name: 'EP1'
    tier: 'ElasticPremium'
  }
  managedIdentityName: '#{{ infraResourceNamePrefix }}#{{ nc_resource_managedidentity }}#{{ nc_instance_regionid }}01-adp-function-app'
}

param platformKeyVault = {
  name: '#{{ infraResourceNamePrefix }}#{{ nc_resource_keyvault }}#{{ nc_instance_regionid }}02'
  secretName: '#{{ deploymentTriggerStorageConnectionStringSecretName }}'
  deploymentTriggerStorageConnectionString: '#{{ deploymentTriggerStorageConnectionString }}'
}

param applicationInsightsName = '#{{ applicationInsightsName }}'
