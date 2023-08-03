@description('Required. The parameter object for the virtual network. The object must contain the name,skuName,resourceGroup and subnetPrivateEndpoints values.')
param vnet object

@description('Required. The parameter object for keyvault. The object must contain the name, enableSoftDelete, enablePurgeProtection and softDeleteRetentionInDays values.')
param keyVault object

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. Environment name.')
param environment string

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

module vaults 'br/SharedDefraRegistry:key-vault.vaults:0.5.6' = {
  name: 'app-keyvault-${deploymentDate}'
  params: {
    name: keyVault.name
    tags: combinedTags
    vaultSku: keyVault.skuName
    enableRbacAuthorization: true    
    enableSoftDelete: bool(keyVault.enableSoftDelete)
    enablePurgeProtection: bool(keyVault.enablePurgeProtection)
    softDeleteRetentionInDays: int(keyVault.softDeleteRetentionInDays)
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    privateEndpoints: [
      {
        service: 'vault'
        subnetResourceId: resourceId(vnet.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnet.name, vnet.subnetPrivateEndpoints)
        tags: combinedTags
      }
    ]
  }
}
