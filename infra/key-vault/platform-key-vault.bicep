@description('Required. Name of the Key Vault. Must be globally unique.')
@maxLength(24)
param keyVaultName string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. Environment name.')
param environment string

@description('Required. Switch to enable/disable Key Vault\'s soft delete feature.')
param enableSoftDelete bool

@description('Required. Provide \'true\' to enable Key Vault\'s purge protection feature.')
param enablePurgeProtection bool

@description('Required. softDelete data retention days. It accepts >=7 and <=90.')
param softDeleteRetentionInDays int

@description('Required. Array of role assignment objects that contain the \'roleDefinitionIdOrName\' and \'principalId\' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
param roleAssignments array

@description('Optional. Specifies the SKU for the vault.')
@allowed(
  [
    'standard'
    'premium'
  ])
param skuName string = 'premium'

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
  Purpose: 'CDO Platform KeyVault Store'
  Tier: 'Shared'
}
var tags = union(loadJsonContent('../default-tags.json'), customTags)

module vaults 'br/SharedDefraRegistry:key-vault.vaults:0.5.6' = {
  name: 'platform-keyvault-${deploymentDate}'
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
    roleAssignments: roleAssignments
  }
}
