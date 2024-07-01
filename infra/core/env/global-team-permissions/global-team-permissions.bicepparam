using './global-team-permissions.bicep'

param appInsightsName = '#{{ applicationInsightsName }}'
param appKeyVaultName = '#{{ infraResourceNamePrefix }}#{{ nc_resource_keyvault }}#{{ nc_instance_regionid }}01'
param appConfigurationName = '#{{ infraResourceNamePrefix }}#{{ nc_resource_appconfiguration }}#{{ nc_instance_regionid }}01'
param principalId = '#{{ globalReadGroupObjectId }}'

