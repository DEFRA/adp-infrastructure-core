using 'key-vault-public.bicep'

param keyVault = {
  name: '#{{ infraResourceNamePrefix }}#{{ nc_resource_keyvault }}#{{ nc_instance_regionid }}03'
  skuName: 'premium'
  enableSoftDelete: '#{{ keyvaultEnableSoftDelete }}'
  enablePurgeProtection: '#{{ keyvaultEnablePurgeProtection }}'
  softDeleteRetentionInDays: '#{{ keyvaultSoftDeleteRetentionInDays }}'
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
    roleDefinitionIdOrName: 'Key Vault Reader'
    description: 'Key Vault Reader Role Assignment'
    principalType: 'Group'
    principalId: '#{{ aadPlatformEngineersUserGroupObjectId }}'
  }
]

param keyvaultType = 'Application'

param ipRules = []
