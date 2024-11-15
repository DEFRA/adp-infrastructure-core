@description('Required. The VNET Infra object.')
param vnet object
@description('Required. The Flow Logs object.')
param flowLogs object
@description('Required. The Storage Account object.')
param storageAccount object
@description('Required. The Azure region where the resources will be deployed.')
param location string
@description('Required. Environment name.')
param environment string
@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')
@description('Optional. Resource group for flow log storage account.')
param servicesResourceGroup string


var commonTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
  Purpose: 'ADP-VIRTUAL-NETWORK'
}
var tags = union(loadJsonContent('../default-tags.json'), commonTags)

var storageAccountToLower = toLower(storageAccount.name)

resource storageAccountResource 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  scope: resourceGroup(servicesResourceGroup)
  name: storageAccountToLower
}

var storageAccountResourceId = storageAccountResource.id

resource vnetResource 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  scope: resourceGroup(vnet.resourceGroup)
  name: vnet.name
}

var vnetResourceId = vnetResource.id

var locationToLower = toLower(location)

resource flowLog 'Microsoft.Network/networkWatchers/flowLogs@2024-03-01' = {
  name: 'NetworkWatcher_${locationToLower}/${flowLogs.name}'
  location: location
  tags: tags
  properties: {
    targetResourceId: vnetResourceId
    storageId: storageAccountResourceId
    enabled: flowLogs.enabled
    retentionPolicy: {
      days: flowLogs.retentionDays
      enabled: true
    }
    format: {
      type: 'JSON'
      version: 2
    }
  }
}
