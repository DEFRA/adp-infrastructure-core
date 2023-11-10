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

var roleAssignments = [
  {
    roleDefinitionIdOrName: 'Key Vault Secrets Officer'
    description: 'Key Vault Secrets Officer Role Assignment'
    principalIds: [
      principalId
    ]
    principalType: 'ServicePrincipal'
  }
]

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}

var defaultTags = union(json(loadTextContent('../../common/default-tags.json')), customTags)

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
    name: '${keyVault.name}'
    tags: union(defaultTags, keyVaultTags)
    vaultSku: keyVault.skuName
    lock: 'CanNotDelete'
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
    keys: [
      {
        name: 'aksKms5'
        kty: 'RSA'
        keySize: 2048
        keyOps: '[decrypt, encrypt, sign, unwrapKey, verify, wrapKey]'
      }
    ]
  }
}
