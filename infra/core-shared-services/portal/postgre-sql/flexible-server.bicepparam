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
  name: '#{{ ssvVirtualNetworkName }}'
  resourceGroup: '#{{ ssvVirtualNetworkResourceGroup }}'
  subnetPostgreSql: '#{{ networkResourceNamePrefix }}#{{ nc_resource_subnet }}#{{ nc_instance_regionid }}02'
}

param keyvaultName = '$(ssvResourceNamePrefix)$(nc_resource_keyvault)$(nc_shared_instance_regionid)03'

param privateDnsZone = {
  name: '#{{ dnsResourceNamePrefix }}#{{ nc_resource_dnszone }}#{{ nc_instance_regionid }}01.private.postgres.database.azure.com'
  resourceGroup: '$(ssvResourceNamePrefix)$(nc_resource_resourcegroup)$(nc_shared_instance_regionid)03'
}

param diagnostics = {
  diagnosticLogCategoriesToEnable: [
    'allLogs'
  ]
  diagnosticMetricsToEnable: [
    'AllMetrics'
  ]
}

param location = '#{{ location }}'

param environment = '#{{ environment }}'
