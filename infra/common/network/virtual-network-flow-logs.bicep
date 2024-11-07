@description('Required. The VNET Infra object.')
param vnet object

@description('Required. The Azure region where the resources will be deployed.')
param location string
@description('Required. Environment name.')
param environment string
// @description('Required. Boolean value to enable or disable resource lock.')
// param resourceLockEnabled bool
@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')
// param virtualNetworkResourceGroup string
// param virtualNetworkName string
// @description('Optional. Enable VNET flow logs.')
// param enableFlowLogs bool = false
// @description('Optional. VNET flow log configuration')
// param flowLogs array


var commonTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
  Purpose: 'ADP-VIRTUAL-NETWORK'
}
var tags = union(loadJsonContent('../default-tags.json'), commonTags)

var locationToLower = toLower(location)

// resource vnetFlowLogs 'Microsoft.Network/networkWatchers/flowLogs@2024-03-01' = {
//   location: location
//   name: '${vnet.name}-flow-logs'
//   properties: {
//     enabled: enableFlowLogs
//     flowAnalyticsConfiguration: {
//       networkWatcherFlowAnalyticsConfiguration: {
//         enabled: enableFlowLogs
//         trafficAnalyticsInterval: int
//         workspaceId: 'string'
//         workspaceRegion: 'string'
//         workspaceResourceId: 'string'
//       }
//     }
//     format: {
//       type: 'string'
//       version: int
//     }
//     retentionPolicy: {
//       days: int
//       enabled: bool
//     }
//     storageId: 'string'
//     targetResourceId: 'string'
//   }
//   tags: {
//     {customized property}: 'string'
//   }
// }

// resource networkWatcher 'Microsoft.Network/networkWatchers@2022-01-01' = {
//   name: '${vnet.name}-network-watcher'
//   location: location
//   properties: {}
// }

resource storageAccountResource 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  scope: resourceGroup('SNDADPINFRG1401')
  name: 'sndadpinfst1401'
}

var storageAccountResourceId = storageAccountResource.id

resource vnetResource 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  scope: resourceGroup(vnet.resourceGroup)
  name: vnet.name
}

var vnetResourceId = vnetResource.id

resource flowLog 'Microsoft.Network/networkWatchers/flowLogs@2024-03-01' = {
  name: 'NetworkWatcher_${locationToLower}/${vnet.name}-flow-log'
  location: location
  tags: tags
  properties: {
    targetResourceId: vnetResourceId
    storageId: storageAccountResourceId
    // lock: resourceLockEnabled ? 'CanNotDelete' : null
    enabled: true
    retentionPolicy: {
      days: 7
      enabled: true
    }
    format: {
      type: 'JSON'
      version: 2
    }
  }
}

// module vnetFlowLogs 'br/SharedDefraRegistry:network.network-watcher:0.4.9' = {
//   name: 'virtual-network-flow-logs-${deploymentDate}'
//   params: {
//     name: '${vnet.name}-flow-logs'
//     location: location
//     lock: resourceLockEnabled ? { name: null, kind: 'CanNotDelete' } : null
//     tags: tags
//     enableDefaultTelemetry: true
//     flowLogs: [
//         {
//           name: '#{{ networkResourceNamePrefix }}#{{ nc_resource_subnet }}#{{ nc_instance_regionid }}01-flow-logs'
//           storageId: storageAccountResourceId
//           targetResourceId: vnetResourceId
//           networkWatcherName: 'NetworkWatcher_${locationToLower}'
//         }
//       ]
//   }
// }
