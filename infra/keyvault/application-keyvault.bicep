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
  Description: 'CDO Platform KeyVault Store'
}

@description('Required. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Required. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}

var defaultTags = json(loadTextContent('../default-tags.json'))
var combinedTags = union(defaultTags, tags, customTags)

@description('Required. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}

var tags = union(loadJsonContent('../default-tags.json'), customTags)

var combinedTags = union(tags, customTags)

resource vnetResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  scope: subscription()
  name: vnet.resourceGroup
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-02-01' existing = {
  scope: vnetResourceGroup
  name: vnet.name
  resource privateEndpointSubnet 'subnets@2023-02-01' existing = {
    name: vnet.subnetPrivateEndpoints
  }
}
module vaults 'br/SharedDefraRegistry:key-vault.vaults:0.5.6' = {
  name: 'app-keyvault-${deploymentDate}'
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
      defaultAction: 'Deny'
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
