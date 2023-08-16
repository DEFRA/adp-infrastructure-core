@description('Required. The parameter object for the virtual network. The object must contain the name,skuName,resourceGroup and subnetPrivateEndpoints values.')
param vnet object

@description('Required. Name of your storage account. The parameter object for storageAccount.')
param storageAccount object

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. Environment name.')
param environment string

@allowed([
  'Storage'
  'StorageV2'
  'BlobStorage'
  'FileStorage'
  'BlockBlobStorage'
])
@description('Optional. Type of Storage Account to create for the storage account.')
param kind string = 'StorageV2'

@description('Optional. Indicates whether indirect CName validation is enabled. This should only be set on updates.')
param customDomainUseSubDomainName bool = false

@description('Optional. Allows you to specify the type of endpoint. Set this to AzureDNSZone to create a large number of accounts in a single subscription, which creates accounts in an Azure DNS Zone and the endpoint URL will have an alphanumeric DNS Zone identifier.')
@allowed([
  ''
  'AzureDnsZone'
  'Standard'
])
param dnsEndpointType string = ''

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}

var defaultTags = union(json(loadTextContent('../default-tags.json')), customTags)

var storageAccountTags = {
  Name: storageAccount.name
  Purpose: 'Storage Account'
  Tier: 'Shared'
}

var storageAccountPrivateEndpointTags = {
  Name: storageAccount.privateEndpointName
  Purpose: 'App Configuration private endpoint'
  Tier: 'Shared'
}

module storageAccounts 'br/SharedDefraRegistry:storage.storage-accounts:0.5.8' = {
  name: 'app-storageAccount-${deploymentDate}'
  params: {
    name: toLower(storageAccount.name)
    tags: union(defaultTags, storageAccountTags)
    skuName: storageAccount.skuName
    lock: 'CanNotDelete'
    kind: kind
    dnsEndpointType: dnsEndpointType
    customDomainUseSubDomainName: customDomainUseSubDomainName
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    publicNetworkAccess: 'Disabled'
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
