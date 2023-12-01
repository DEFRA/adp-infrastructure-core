@description('Required. The parameter object for the azure monitor workspace service. The object must contain name, resourceGroup and subscriptionId.')
param azureMonitorWorkspace object = {
  name: 'SNDADPINFMW1401'
  resourceGroup: 'sndadpinfrg1401'
}
@description('Required. The clustername to scope the data collection rule association.')
param clusterName string = 'SNDADPINFAK1401'
@description('Required. The Azure region where the resources will be deployed.')
param location string = 'UKSouth'
@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

var dataCollectionEndpointName = 'MSProm-${location}-${clusterName}'
var dataCollectionRuleName = 'MSProm-${location}-${clusterName}'
var dataCollectionRuleAssociationName = 'MSProm-${location}-${clusterName}'

resource managedGrafana 'Microsoft.Dashboard/grafana@2022-08-01' existing = {
  scope: resourceGroup('7dc5bbdf-72d7-42ca-ac23-eb5eea3764b4','SSVADPINFRG3401')
  name: 'SSVADPINFMG3401'
}

resource managedCluster 'Microsoft.ContainerService/managedClusters@2023-07-02-preview' existing = {
  name: clusterName
}

resource monitorWorkspace 'Microsoft.Monitor/accounts@2021-06-03-preview' existing = {
  scope: resourceGroup(azureMonitorWorkspace.resourceGroup)
  name: azureMonitorWorkspace.name
}

module dataCollectionEndpoint 'br/SharedDefraRegistry:insights.data-collection-endpoint:0.4.8' = {
  // scope: resourceGroup(azureMonitorWorkspace.resourceGroup)
  name: 'prometheus-data-collection-endpoint-${deploymentDate}'
  params: {
    name: dataCollectionEndpointName
    location: location
    kind: 'Linux'
  }
}

module dataCollectionRule 'br/SharedDefraRegistry:insights.data-collection-rule:0.4.8' = {
  // scope: resourceGroup(azureMonitorWorkspace.resourceGroup)
  name: 'prometheus-data-collection-rule-${deploymentDate}'
  params: {
    name: dataCollectionRuleName
    location: location
    kind: 'Linux'
    dataCollectionEndpointId: dataCollectionEndpoint.outputs.resourceId
    description: 'DCR for Azure Monitor Metrics Profile (Managed Prometheus)'
    dataFlows: [
      {
        destinations: [
          'MonitoringAccount1'
        ]
        streams: [
          'Microsoft-PrometheusMetrics'
        ]
      }
    ]
    dataSources: {
      prometheusForwarder: [
        {
          name: 'PrometheusDataSource'
          streams: [
            'Microsoft-PrometheusMetrics'
          ]
          labelIncludeFilter: {}
        }
      ]
    }
    destinations: {
      monitoringAccounts: [
        {
          accountResourceId: monitorWorkspace.id
          name: 'MonitoringAccount1'
        }
      ]
    }
  }
}

resource dataCollectionRuleAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2021-09-01-preview' = {
  name: dataCollectionRuleAssociationName
  scope: managedCluster
  properties: {
    description: 'Association of data collection rule. Deleting this association will break the data collection for this AKS Cluster.'
    dataCollectionRuleId: dataCollectionRule.outputs.resourceId
  }
}

module prometheusRuleGroup './prometheus-rule-groups.bicep' = {
  scope: resourceGroup(azureMonitorWorkspace.resourceGroup)
  name: 'prometheus-rul-group-${deploymentDate}'
  params: {
    azureMonitorWorkspace: {
      name: azureMonitorWorkspace.name
      resourceGroup: azureMonitorWorkspace.resourceGroup
    }
    clusterName: clusterName
    location: location
  }
}

// resource dataCollectionRuleAssociation2 'Microsoft.Insights/dataCollectionRuleAssociations@2021-09-01-preview' = {
//   name: '${dataCollectionRuleAssociationName}-2'
//   scope: managedCluster
//   properties: {
//     description: 'Association of data collection rule. Deleting this association will break the data collection for this AKS Cluster.'
//     dataCollectionRuleId: monitorWorkspace.properties.defaultIngestionSettings.dataCollectionRuleResourceId
//   }
// }

// resource nodeRecordingRuleGroupResource 'Microsoft.AlertsManagement/prometheusRuleGroups@2023-03-01' = {
//   name: nodeRecordingRuleGroupName
//   location: location
//   properties: {
//     description: '${nodeRecordingRuleGroupDescription}-${version}'
//     scopes: [
//       monitorWorkspace.id
//       managedCluster.id
//     ]
//     clusterName: clusterName
//     interval: 'PT1M'
//     rules: [
//       {
//         record: 'instance:node_num_cpu:sum'
//         expression: 'count without (cpu, mode) (  node_cpu_seconds_total{job="node",mode="idle"})'
//       }
//       {
//         record: 'instance:node_cpu_utilisation:rate5m'
//         expression: '1 - avg without (cpu) (  sum without (mode) (rate(node_cpu_seconds_total{job="node", mode=~"idle|iowait|steal"}[5m])))'
//       }
//       {
//         record: 'instance:node_load1_per_cpu:ratio'
//         expression: '(  node_load1{job="node"}/  instance:node_num_cpu:sum{job="node"})'
//       }
//       {
//         record: 'instance:node_memory_utilisation:ratio'
//         expression: '1 - (  (    node_memory_MemAvailable_bytes{job="node"}    or    (      node_memory_Buffers_bytes{job="node"}      +      node_memory_Cached_bytes{job="node"}      +      node_memory_MemFree_bytes{job="node"}      +      node_memory_Slab_bytes{job="node"}    )  )/  node_memory_MemTotal_bytes{job="node"})'
//       }
//       {
//         record: 'instance:node_vmstat_pgmajfault:rate5m'
//         expression: 'rate(node_vmstat_pgmajfault{job="node"}[5m])'
//       }
//       {
//         record: 'instance_device:node_disk_io_time_seconds:rate5m'
//         expression: 'rate(node_disk_io_time_seconds_total{job="node", device!=""}[5m])'
//       }
//       {
//         record: 'instance_device:node_disk_io_time_weighted_seconds:rate5m'
//         expression: 'rate(node_disk_io_time_weighted_seconds_total{job="node", device!=""}[5m])'
//       }
//       {
//         record: 'instance:node_network_receive_bytes_excluding_lo:rate5m'
//         expression: 'sum without (device) (  rate(node_network_receive_bytes_total{job="node", device!="lo"}[5m]))'
//       }
//       {
//         record: 'instance:node_network_transmit_bytes_excluding_lo:rate5m'
//         expression: 'sum without (device) (  rate(node_network_transmit_bytes_total{job="node", device!="lo"}[5m]))'
//       }
//       {
//         record: 'instance:node_network_receive_drop_excluding_lo:rate5m'
//         expression: 'sum without (device) (  rate(node_network_receive_drop_total{job="node", device!="lo"}[5m]))'
//       }
//       {
//         record: 'instance:node_network_transmit_drop_excluding_lo:rate5m'
//         expression: 'sum without (device) (  rate(node_network_transmit_drop_total{job="node", device!="lo"}[5m]))'
//       }
//     ]
//   }
// }

// resource aksClusterUpdate 'Microsoft.ContainerService/managedClusters@2023-07-02-preview' = {
//   name: clusterName
//   location: location
//   properties: {
//     azureMonitorProfile: {
//       metrics: {
//         enabled: true
//         kubeStateMetrics: {
//           // a comma-separated list of Kubernetes annotations keys that will be used in the resource's labels metric.
//           // By default the metric contains only name and namespace labels. To include additional annotations provide
//           // a list of resource names in their plural form and Kubernetes annotation keys, you would like to allow for them.
//           // A single * can be provided per resource instead to allow any annotations, but that has severe performance implications.
//           metricLabelsAllowlist: ''
//           // a comma-separated list of additional Kubernetes label keys that will be used in the resource's labels metric.
//           // By default the metric contains only name and namespace labels. To include additional labels provide
//           // a list of resource names in their plural form and Kubernetes label keys you would like to allow for them.
//           // A single * can be provided per resource instead to allow any labels, but that has severe performance implications.
//           metricAnnotationsAllowList: ''
//         }
//       }
//     }
//   }
// }

module monitorWorkspaceRoleAssignment 'monitoring-reader.bicep' = {
  name: 'monitor-workspace-monitoring-reader-role-${deploymentDate}'
  scope: resourceGroup(azureMonitorWorkspace.resourceGroup)
  params: {
    azureMonitorWorkspaceName: azureMonitorWorkspace.name
    principalId: managedGrafana.identity.principalId
  }
}
