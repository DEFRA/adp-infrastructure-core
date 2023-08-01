@description('Required. Name of the Key Vault. Must be globally unique.')
@maxLength(24)
param keyVaultName string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. Environment name.')
param environment string

@description('Optional. Service code.')
param serviceCode string = 'CDO'

@description('Required. Switch to enable/disable Key Vault\'s soft delete feature.')
param enableSoftDelete bool

@description('Required. Provide \'true\' to enable Key Vault\'s purge protection feature.')
param enablePurgeProtection bool

@description('Required. softDelete data retention days. It accepts >=7 and <=90.')
param softDeleteRetentionInDays int

@description('Optional. Resource tags.')
param tags object = {
  ServiceCode: serviceCode
  Environment: environment
  Description: 'CDO Platform KeyVault Store'
}

@description('Optional. Specifies the SKU for the vault.')
@allowed(
  [
    'standard'
    'premium'
  ])
param skuName string = 'standard'

module vaults 'br/SharedDefraRegistry:key-vault.vaults:0.5.6' = {
  name: '${uniqueString(deployment().name, location)}-keyvault'
  params: {
    name: keyVaultName
    tags: tags
    vaultSku: skuName
    enableRbacAuthorization: true    
    enableSoftDelete: enableSoftDelete
    enablePurgeProtection: enablePurgeProtection
    softDeleteRetentionInDays: softDeleteRetentionInDays
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    privateEndpoints: [
      {
        service: 'vault'
        subnetResourceId: nestedDependencies.outputs.subnetResourceId
        tags: {
          Environment: 'Non-Prod'
          Role: 'DeploymentValidation'
        }
      }
    ]
  }
}
