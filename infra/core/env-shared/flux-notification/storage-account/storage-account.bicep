@description('Required. The parameter object for the virtual network. The object must contain the name,skuName,resourceGroup and subnetPrivateEndpoints values.')
param vnet object

@description('Required. Name of your storage account. The parameter object for storageAccount.')
param storageAccount object

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. Environment name.')
param environment string

@description('Required. Sub Environment name.')
param subEnvironment string

@allowed([
  'Storage'
  'StorageV2'
  'BlobStorage'
  'FileStorage'
  'BlockBlobStorage'
])
@description('Optional. Type of Storage Account to create for the storage account.')
param kind string = 'StorageV2'

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

@description('Required. Boolean value to enable or disable resource lock.')
param resourceLockEnabled bool

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
  SubEnvironment: subEnvironment
}

var defaultTags = union(json(loadTextContent('../../../../common/default-tags.json')), customTags)

var storageAccountTags = {
  Name: storageAccount.name
  Purpose: 'Flux Notification Storage Account'
  Tier: 'Shared'
}

var storageAccountPrivateEndpointTags = {
  Name: storageAccount.privateEndpointName
  Purpose: 'Flux Notification Storage Account private endpoint'
  Tier: 'Shared'
}

module storageAccounts 'br/SharedDefraRegistry:storage.storage-account:0.5.3' = {
  name: 'app-storageAccount-${deploymentDate}'
  params: {
    name: toLower(storageAccount.name)
    tags: union(defaultTags, storageAccountTags)
    skuName: storageAccount.skuName
    lock: resourceLockEnabled ? 'CanNotDelete' : null
    kind: kind
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    publicNetworkAccess: 'Disabled'
    blobServices: {
      containers: [
        {
          name: '${storageAccount.containerName}'
        }
      ]
    }
    privateEndpoints: [
      {
        name: storageAccount.privateEndpointName
        service: 'blob'
        subnetResourceId: resourceId(vnet.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnet.name, vnet.subnetPrivateEndpoints)
        tags: union(defaultTags, storageAccountPrivateEndpointTags)
      }
    ]
  }
}

