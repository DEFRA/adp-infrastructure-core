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

// TODO: Create new var for storage account name
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


// Keeping below until testing has been completed

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




// var vnetResourceId = virtualNetwork.outputs.resourceId

// var locationToLower = toLower(location)

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



// resource flowLog 'Microsoft.Network/networkWatchers/flowLogs@2024-03-01' = {
//   name: 'NetworkWatcher_${locationToLower}/${vnet.name}-flow-log'
//   scope: resourceGroup('NetworkWatcherRG')
//   location: location
//   properties: {
//     targetResourceId: vnetResourceId
//     storageId: storageAccountResourceId
//     enabled: true
//     retentionPolicy: {
//       days: 7
//       enabled: true
//     }
//     format: {
//       type: 'JSON'
//       version: 2
//     }
//   }
// }

// resource storageAccountResource 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
//   name: 'sndadpinfst1401'
// }

// var storageAccountResourceId = storageAccountResource.id


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



// "flowLogs": {
//   "value": {
//     "name": "#{{ infraResourceNamePrefix }}#{{ nc_resource_flow_logs }}#{{ nc_instance_regionid }}01",
//     "resourceGroup": "#{{ virtualNetworkResourceGroup }}"
//   }
// },


// var locationToLower = toLower(location)
