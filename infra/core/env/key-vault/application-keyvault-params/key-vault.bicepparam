using '../key-vault.bicep'

param keyVault = {
  name: '#{{ infraResourceNamePrefix }}#{{ nc_resource_keyvault }}#{{ nc_instance_regionid }}01'
  privateEndpointName: '#{{ infraResourceNamePrefix }}#{{ nc_resource_privateendpoint }}#{{ nc_instance_regionid }}03'
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

param principalId = az.getSecret(
  '#{{ ssvSubscriptionId }}',
  '#{{ ssvSharedResourceGroup }}',
  '#{{ ssvPlatformKeyVaultName }}',
  '#{{ tier2ApplicationSPObjectIdSecretName }}'
)

param roleAssignment = [
  {
    roleDefinitionIdOrName: 'Key Vault Secrets Officer'
    description: 'Key Vault Secrets Officer Role Assignment'
    principalType: 'ServicePrincipal'
    principalId: ''
  }
  {
    roleDefinitionIdOrName: 'Key Vault Secrets Officer'
    description: 'Key Vault Secrets Officer Role Assignment'
    principalType: 'ServicePrincipal'
    principalId: '#{{ ssvAppRegServicePrincipalId }}'
  }
  {
    roleDefinitionIdOrName: 'Key Vault Reader'
    description: 'Key Vault Reader Role Assignment'
    principalType: 'Group'
    principalId: '#{{ aadPlatformEngineersUserGroupObjectId }}'
  }
]

param keyvaultType = 'Application'

param resourceLockEnabled = #{{ resourceLockEnabled }}
