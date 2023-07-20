param keyVaultName string
param location string = resourceGroup().location
param environment string
param serviceCode string = 'CDO'
param enableSoftDelete bool
param enablePurgeProtection bool
param softDeleteRetentionInDays int
param roleAssignments array
param tags object = {
  ServiceCode: serviceCode
  Environment: environment
  Description: 'CDO Central KeyVault Store'
}

@allowed(
  [
    'standard'
    'premium'
  ])
param skuName string = 'standard'

module vaults 'br:snd2cdoinfac1401.azurecr.io/bicep/modules/key-vault.vaults:0.5.6' = {
  name: '${uniqueString(deployment().name, location)}-test-kvvmin'
  params: {
    // Required parameters
    name: keyVaultName
    // Non-required parameters
    tags: tags
    vaultSku: skuName
    enableRbacAuthorization: True    
    enableSoftDelete: enableSoftDelete
    enablePurgeProtection: enablePurgeProtection
    softDeleteRetentionInDays: softDeleteRetentionInDays
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    roleAssignments: roleAssignments
  }
}
