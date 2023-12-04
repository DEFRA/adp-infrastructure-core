@description('Required. The parameter object for the azure monitor workspace service. The object must contain name, resourceGroup and subscriptionId.')
param azureMonitorWorkspace object = {
  name: 'SNDADPINFMW1401'
  resourceGroup: 'sndadpinfrg1401'
}
@description('Required. The parameter object for the managed grafana instance. The object must contain name of the name, resourceGroup and subscriptionId.')
param grafana object = {
  name: 'SSVADPINFMG3401'
  subscriptionId: '7dc5bbdf-72d7-42ca-ac23-eb5eea3764b4'
  resourceGroup: 'SSVADPINFRG3401'
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
  scope: resourceGroup(grafana.subscriptionId,grafana.resourceGroup)
  name: grafana.name
}

resource managedCluster 'Microsoft.ContainerService/managedClusters@2023-07-02-preview' existing = {
  name: clusterName
}

resource monitorWorkspace 'Microsoft.Monitor/accounts@2021-06-03-preview' existing = {
  scope: resourceGroup(azureMonitorWorkspace.resourceGroup)
  name: azureMonitorWorkspace.name
}

module dataCollectionEndpoint 'br/SharedDefraRegistry:insights.data-collection-endpoint:0.4.8' = {
  name: 'prometheus-data-collection-endpoint-${deploymentDate}'
  params: {
    name: dataCollectionEndpointName
    location: location
    kind: 'Linux'
    publicNetworkAccess: 'Enabled'
  }
}

module dataCollectionRule 'br/SharedDefraRegistry:insights.data-collection-rule:0.4.8' = {
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

resource dataCollectionRuleAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2022-06-01' = {
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
    clusterName: clusterName
    location: location 
    clusterResourceId: managedCluster.id
    monitorWorkspaceResourceId: monitorWorkspace.id
  }
}

// resource dataCollectionRuleAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2021-09-01-preview' = {
//   name: dataCollectionRuleAssociationName
//   scope: managedCluster
//   properties: {
//     description: 'Association of data collection rule. Deleting this association will break the data collection for this AKS Cluster.'
//     dataCollectionRuleId: monitorWorkspace.properties.defaultIngestionSettings.dataCollectionRuleResourceId
//   }
// }

module monitorWorkspaceRoleAssignment 'monitoring-data-reader.bicep' = {
  name: 'monitor-workspace-monitoring-reader-role-${deploymentDate}'
  scope: resourceGroup(azureMonitorWorkspace.resourceGroup)
  params: {
    azureMonitorWorkspaceName: azureMonitorWorkspace.name
    principalId: managedGrafana.identity.principalId
  }
}

resource aksClusterUpdate 'Microsoft.ContainerService/managedClusters@2023-07-02-preview' = {
  dependsOn: [dataCollectionRuleAssociation]
  name: clusterName
  location: location
  properties: {
    azureMonitorProfile: {
      metrics: {
        enabled: true
        kubeStateMetrics: {
          metricLabelsAllowlist: ''
          metricAnnotationsAllowList: ''
        }
      }
    }
  }
}
