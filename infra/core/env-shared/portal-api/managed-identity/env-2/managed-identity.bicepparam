using '../managed-identity.bicep'

param managedIdentity = {
  name: '#{{ infraResourceNamePrefix }}#{{ nc_resource_managedidentity }}#{{ nc_instance_regionid }}02-adp-portal-api'
}

param environment = '#{{ environment }}'
param location = '#{{ location }}'

param containerRegistry = {
  name: '#{{ infraResourceNamePrefix }}#{{ nc_resource_containerregistry }}#{{ nc_instance_regionid }}01'
  subscriptionId: '#{{ subscriptionId }}'
  resourceGroup: '#{{ ssvSharedResourceGroup }}'
}

param appKeyVault = {
  name: '#{{ ssvResourceNamePrefix }}#{{ nc_resource_keyvault }}#{{ nc_shared_instance_regionid }}03'
  subscriptionId: '#{{ subscriptionId }}'
  resourceGroup: '#{{ portalResourceGroup2 }}'
}

param platformKeyVault = {
  name: '#{{ ssvResourceNamePrefix }}#{{ nc_resource_keyvault }}#{{ nc_shared_instance_regionid }}01'
  subscriptionId: '#{{ subscriptionId }}'
  resourceGroup: '#{{ ssvSharedResourceGroup }}'
}

param secrets = [
  'ADO-DefraGovUK-AAD-ADP-#{{ssvEnvironment}}#{{environmentId}}'
  'ADO-DefraGovUK-AAD-ADP-#{{ssvEnvironment}}#{{environmentId}}-ClientId'
  'ADO-DefraGovUK-AAD-ADP-#{{ssvEnvironment}}#{{environmentId}}-ObjectId'
]
