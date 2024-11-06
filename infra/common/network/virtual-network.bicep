@description('Required. The VNET Infra object.')
param vnet object

@description('Required. The subnets object.')
param subnets array

@allowed([
  'UKSouth'
])
@description('Required. The Azure region where the resources will be deployed.')
param location string
@description('Required. Environment name.')
param environment string
@description('Required. Boolean value to enable or disable resource lock.')
param resourceLockEnabled bool
@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')
@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')
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

var vnetResourceId = virtualNetwork.outputs.resourceId

module virtualNetwork 'br/SharedDefraRegistry:network.virtual-network:0.4.2' = {
  name: 'virtual-network-${deploymentDate}'
  params: {
    name: vnet.name
    location: location
    lock: resourceLockEnabled ? 'CanNotDelete' : null
    tags: tags
    enableDefaultTelemetry: true
    addressPrefixes: vnet.addressPrefixes
    dnsServers: vnet.dnsServers
    subnets: subnets
  }
}


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
  name: 'sndadpinfst1401'
}

var storageAccountResourceId = storageAccountResource.id

resource flowLog 'Microsoft.Network/networkWatchers/flowLogs@2022-01-01' = {
  name: '${vnet.name}-flow-log'
  location: location
  properties: {
    targetResourceId: vnetResourceId
    storageId: storageAccountResourceId
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



// module vnetFlowLogs 'br/SharedDefraRegistry:network.watcher:0.4.9' = {
//   name: 'virtual-network-flow-logs-${deploymentDate}'
//   params: {
//     name: '${vnet.name}-flow-logs'
//     location: location
//     lock: resourceLockEnabled ? 'CanNotDelete' : null
//     tags: tags
//     enableDefaultTelemetry: true
//     flowLogs: flowLogs
//   }
// }
