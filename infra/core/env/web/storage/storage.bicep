@description('Required. The parameter object for the virtual network. The object must contain the name,resourceGroup and subnetPrivateEndpoints values.')
param vnet object

@description('Required. The parameter object for the App Service storage account. The object must contain the name, privateEndpointNameBlob, privateEndpointNameFile, skuName, kind and fileShareName')
param storageAccount object = {
  name: 'sndadpinfst1402'
  privateEndpointNameBlob: 'SNDADPINFPE1408'
  privateEndpointNameFile: 'SNDADPINFPE1409'
  skuName: 'Standard_ZRS'
  fileShareName: 'function-content-share'
  kind: 'StorageV2'
}

@description('Required. Environment name.')
param environment string

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

@description('Optional. The Azure region where the resources will be deployed.')
param location string = resourceGroup().location

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}
var tags = union(loadJsonContent('../../../../common/default-tags.json'), customTags)

var storageAccountTags = {
  Name: storageAccount.name
  Purpose: 'FunctionApp Storage Account'
  Tier: 'Shared'
}

var storageAccountBlobPrivateEndpointTags = {
  Name: storageAccount.privateEndpointNameBlob
  Purpose: 'FunctionApp Storage Account private endpoint'
  Tier: 'Shared'
}

var storageAccountFilePrivateEndpointTags = {
  Name: storageAccount.privateEndpointNameFile
  Purpose: 'FunctionApp Storage Account private endpoint'
  Tier: 'Shared'
}

module storageAccountResource 'br/SharedDefraRegistry:storage.storage-account:0.5.3' = {
  name: 'functionapp-storageAccount-${deploymentDate}'
  params: {
    name: toLower(storageAccount.name)
    tags: union(tags, storageAccountTags)
    skuName: storageAccount.skuName
    lock: 'CanNotDelete'
    kind: storageAccount.kind
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    publicNetworkAccess: 'Disabled'
    fileServices: {
      shares: [
        {
          name: storageAccount.fileShareName
        }
      ]
    }
    privateEndpoints: [
      {
        name: storageAccount.privateEndpointNameBlob
        service: 'blob'
        subnetResourceId: resourceId(vnet.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnet.name, vnet.subnetPrivateEndpoints)
        tags: union(tags, storageAccountBlobPrivateEndpointTags)
      }
      {
        name: storageAccount.privateEndpointNameFile
        service: 'file'
        subnetResourceId: resourceId(vnet.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnet.name, vnet.subnetPrivateEndpoints)
        tags: union(tags, storageAccountFilePrivateEndpointTags)
      }
    ]
  }
}
