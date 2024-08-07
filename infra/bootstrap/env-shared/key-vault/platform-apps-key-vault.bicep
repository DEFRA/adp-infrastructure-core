@description('Required. The parameter object for the virtual network. The object must contain the name,skuName,resourceGroup and subnetPrivateEndpoints values.')
param vnet object

@description('Required. The parameter object for keyvault. The object must contain the name, enableSoftDelete, enablePurgeProtection and softDeleteRetentionInDays values.')
param keyVault object

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. Environment name.')
param environment string

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

@description('Required. principalId of service connection')
@secure()
param principalId string

@description('Required. Platform Users AD group ID')
param platformUserGroupId string

@description('Required. The parameter object for the application insights.')
param appInsights object

@description('Required. Boolean value to enable or disable resource lock.')
param resourceLockEnabled bool

var roleAssignments = [
  {
    roleDefinitionIdOrName: 'Key Vault Secrets Officer'
    description: 'Key Vault Secrets Officer Role Assignment'
    principalIds: [
      principalId
    ]
    principalType: 'ServicePrincipal'
  }
  {
    roleDefinitionIdOrName: 'Key Vault Reader'
    description: 'Key Vault Reader Role Assignment'
    principalIds: [
      platformUserGroupId
    ]
    principalType: 'Group'
  }
]

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}

var defaultTags = union(json(loadTextContent('../../../common/default-tags.json')), customTags)

var keyVaultTags = {
  Name: keyVault.name
  Purpose: 'Key Vault'
  Tier: 'Shared'
}

var keyVaultPrivateEndpointTags = {
  Name: keyVault.privateEndpointName
  Purpose: 'Keyvault private endpoint'
  Tier: 'Shared'
}

module vaults 'br/SharedDefraRegistry:key-vault.vault:0.5.3' = {
  name: 'app-keyvault-${deploymentDate}'
  params: {
    name: keyVault.name
    tags: union(defaultTags, keyVaultTags)
    vaultSku: keyVault.skuName
    lock: resourceLockEnabled ? 'CanNotDelete' : null
    enableRbacAuthorization: true    
    enableSoftDelete: bool(keyVault.enableSoftDelete)
    enablePurgeProtection: bool(keyVault.enablePurgeProtection)
    softDeleteRetentionInDays: int(keyVault.softDeleteRetentionInDays)
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    publicNetworkAccess: 'Disabled'
    privateEndpoints: [
      {
        name: keyVault.privateEndpointName
        service: 'vault'
        subnetResourceId: resourceId(vnet.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnet.name, vnet.subnetPrivateEndpoints)
        tags: union(defaultTags, keyVaultPrivateEndpointTags)
      }
    ]
    roleAssignments: roleAssignments
  }
}

resource appInsightsResource 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsights.name
  scope: resourceGroup(appInsights.resourceGroup)
}

module appninsightsecret './.bicep/storesecret.bicep' = {
  name: 'app-insight-connection'  
  params: {
    keyvaultName: vaults.outputs.name
    appInsightConnectionString: appInsightsResource.properties.ConnectionString
  }
}


