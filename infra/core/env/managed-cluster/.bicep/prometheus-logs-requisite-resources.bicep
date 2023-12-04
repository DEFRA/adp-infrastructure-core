@description('Required. The parameter object for the azure monitor workspace service. The object must contain name, resourceGroup and subscriptionId.')
param azureMonitorWorkspace object
@description('Required. The parameter object for the managed grafana instance. The object must contain name of the name, resourceGroup and subscriptionId.')
param grafana object
@description('Required. The clustername to scope the data collection rule association.')
param clusterName string
@description('Required. The Azure region where the resources will be deployed.')
param location string
@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

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

resource dataCollectionRuleAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2021-09-01-preview' = {
  name: 'MSProm-${location}-${clusterName}'
  scope: managedCluster
  properties: {
    description: 'Association of data collection rule. Deleting this association will break the data collection for this AKS Cluster.'
    dataCollectionRuleId: monitorWorkspace.properties.defaultIngestionSettings.dataCollectionRuleResourceId
  }
}

module prometheusRuleGroup './prometheus-rule-groups.bicep' = {
  scope: resourceGroup(azureMonitorWorkspace.resourceGroup)
  name: 'prometheus-rule-group-${deploymentDate}'
  params: {
    clusterName: clusterName
    location: location 
    clusterResourceId: managedCluster.id
    monitorWorkspaceResourceId: monitorWorkspace.id
  }
}

module monitorWorkspaceRoleAssignment 'monitoring-data-reader.bicep' = {
  name: 'monitor-workspace-monitoring-reader-role-${deploymentDate}'
  scope: resourceGroup(azureMonitorWorkspace.resourceGroup)
  params: {
    azureMonitorWorkspaceName: azureMonitorWorkspace.name
    principalId: managedGrafana.identity.principalId
  }
}
