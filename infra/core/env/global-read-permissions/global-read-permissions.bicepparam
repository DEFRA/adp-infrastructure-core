using './global-read-permissions.bicep'

param appInsightsName = '#{{ applicationInsightsName }}'
param appKeyVaultName = '#{{ infraResourceNamePrefix }}#{{ nc_resource_keyvault }}#{{ nc_instance_regionid }}01'
param appConfigurationName = '#{{ infraResourceNamePrefix }}#{{ nc_resource_appconfiguration }}#{{ nc_instance_regionid }}01'
param principalId = '1035b387-fc03-403d-a992-dbb84603455c'
// param principalId = '#{{ globalReadGroupObjectId }}'

