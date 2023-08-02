@description('Required. The parameter object for the virtual network. The object must contain the name,resourceGroup and subnetPrivateEndpoints values.')
param vnet object

@description('Required. The parameter object for keyvault. The object must contain the name, enableSoftDelete, enablePurgeProtection and softDeleteRetentionInDays values.')
param keyVault object

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. Environment name.')
param environment string

@description('Optional. Service code.')
param serviceCode string = 'CDO'

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

@description('Required. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}

var defaultTags = json(loadTextContent('../default-tags.json'))
var combinedTags = union(defaultTags, tags, customTags)

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
  name: '${uniqueString(deployment().name, location)}-keyvault'
  params: {
    name: keyVault.name
    tags: combinedTags
    vaultSku: skuName
    enableRbacAuthorization: true    
    enableSoftDelete: keyVault.enableSoftDelete
    enablePurgeProtection: keyVault.enablePurgeProtection
    softDeleteRetentionInDays: keyVault.softDeleteRetentionInDays
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    privateEndpoints: [
      {
        service: 'vault'
        subnetResourceId: virtualNetwork::privateEndpointSubnet.id
        tags: combinedTags
      }
    ]
  }
}
