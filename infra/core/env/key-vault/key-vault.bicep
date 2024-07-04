@description('Required. The parameter object for the virtual network. The object must contain the name,skuName,resourceGroup and subnetPrivateEndpoints values.')
param vnet object

@description('Required. The parameter object for keyvault. The object must contain the name, enableSoftDelete, enablePurgeProtection and softDeleteRetentionInDays values.')
param keyVault object

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. Environment name.')
param environment string

@description('Required. Environment name.')
@allowed([
  'Application'
  'Platform'
])
param keyvaultType string

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

@description('Required. principalId of service connection')
@secure()
param principalId string

@description('Required. The parameter object for keyvault roleassignment. The object must contain the roleDefinitionIdOrName, description and principalType.')
param roleAssignment array

@description('Optional. Enable publicNetworkAccess. Default is Disabled')
param publicNetworkAccess string = 'Disabled'

@description('Optional. The parameter array for approved ip rules.')
param defraApprovedIpRules array = []

@description('Optional. The parameter array for approved additional ip rules.')
param additionalApprovedIpRules array = []

var ipv4IpRules = filter(concat(defraApprovedIpRules, additionalApprovedIpRules), rule => !contains(rule, ':'))

var roleAssignments = [
  for item in roleAssignment: {
    roleDefinitionIdOrName: item.roleDefinitionIdOrName
    description: item.description
    principalIds: [
      item.principalId != '' ? item.principalId : principalId
    ]
    principalType: item.principalType
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
  Purpose: '${keyvaultType} Key Vault'
  Tier: 'Shared'
}

var keyVaultPrivateEndpointTags = {
  Name: keyVault.privateEndpointName
  Purpose: '${keyvaultType} Keyvault private endpoint'
  Tier: 'Shared'
}

module vaults 'br/SharedDefraRegistry:key-vault.vault:0.5.3' = {
  name: '${keyvaultType}-keyvault-${deploymentDate}'
  params: {
    name: keyVault.name
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
      ipRules: [
        for rule in ipv4IpRules:  {
          value: rule
        }
      ]
    }    
    publicNetworkAccess: publicNetworkAccess
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
