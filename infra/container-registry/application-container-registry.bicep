@description('Required. The parameter object for the virtual network. The object must contain the name,skuName,resourceGroup and subnetPrivateEndpoints values.')
param vnet object

@description('Required. The parameter object for container registry. The object must contain the name, enableSoftDelete, enablePurgeProtection and softDeleteRetentionInDays values.')
param containerRegistry object

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. Environment name.')
param environment string

@description('Optional. Resource tags.')
param tags object = {
  Description: 'CDO Container Registry'
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

var defaultTags = union(json(loadTextContent('../default-tags.json')), customTags)

module registry 'br/SharedDefraRegistry:key-vault.vaults:0.5.6' = {
  name: 'app-containerregistry-${deploymentDate}'
  params: {
    name: containerRegistry.name
    tags: union(defaultTags, tags)
    vaultSku: containerRegistry.skuName
    enableRbacAuthorization: true    
    enableSoftDelete: bool(containerRegistry.enableSoftDelete)
    enablePurgeProtection: bool(containerRegistry.enablePurgeProtection)
    softDeleteRetentionInDays: int(containerRegistry.softDeleteRetentionInDays)
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    dataEndpointEnabled: dataEndpointEnabled
    publicNetworkAccess: 'Disabled'
  }
}
