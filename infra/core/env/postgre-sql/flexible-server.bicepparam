using './flexible-server.bicep'

param server = {
  name: '#{{ dbsResourceNamePrefix }}#{{ nc_resource_postgresql }}#{{ nc_instance_regionid }}01'
  storageSizeGB: #{{ postgreSqlStorageSizeGB }}
  tier: '#{{ postgreSqlTier }}'
  skuName: '#{{ postgreSqlSkuName }}'
  highAvailability: '#{{ postgreSqlHighAvailability }}'
  availabilityZone: '#{{ postgreSqlAvailabilityZone }}'
}
param vnet = {
  name: '#{{ virtualNetworkName }}'
  resourceGroup: '#{{ virtualNetworkResourceGroup }}'
  subnetPostgreSql: '#{{ networkResourceNamePrefix }}#{{ nc_resource_subnet }}#{{ nc_instance_regionid }}96'
}
param privateDnsZone = {
  name: '#{{ dnsResourceNamePrefix }}#{{ nc_resource_dnszone }}#{{ nc_instance_regionid }}02.private.postgres.database.azure.com'
  resourceGroup: '#{{ dnsResourceGroup }}'
}
param managedIdentityName = '#{{ infraResourceNamePrefix }}#{{ nc_resource_managedidentity }}#{{ nc_instance_regionid }}01-adp-platform-db-aad-admin'
param location = '#{{ location }}'
param environment = '#{{ environment }}'

param platformKeyVault = {
  name: '#{{ ssvInfraResourceNamePrefix }}#{{ nc_resource_keyvault }}#{{ nc_shared_instance_regionid }}01'
  subscriptionId: '#{{ ssvSubscriptionId }}'
  resourceGroup: '#{{ ssvSharedResourceGroup }}'
}

param applicationKeyVault = {
  name: '#{{ infraResourceNamePrefix }}#{{ nc_resource_keyvault }}#{{ nc_instance_regionid }}01'
  resourceGroup: '#{{ servicesResourceGroup }}'
}

param secrets = [
  'ADO-DefraGovUK-AAD-ADP-#{{ssvEnvironment}}#{{nc_shared_instance}}'
  'ADO-DefraGovUK-AAD-ADP-#{{ssvEnvironment}}#{{nc_shared_instance}}-ClientId'
]
