@description('Required. The parameter object for the azure monitor workspace service. The object must contain name, resourceGroup and subscriptionId.')
param azureMonitorWorkspace object
@description('Required. The clustername to scope the data collection rule association.')
param clusterName string

resource managedCluster 'Microsoft.ContainerService/managedClusters@2023-07-02-preview' existing = {
  name: clusterName
}

resource dataCollectionRuleAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2021-09-01-preview' = {
  name: '${azureMonitorWorkspace.name}-${clusterName}'
  scope: managedCluster
  properties: {
    description: 'Association of data collection rule. Deleting this association will break the data collection for this AKS Cluster.'
    dataCollectionRuleId: resourceId(azureMonitorWorkspace.resourceGroup, 'Microsoft.Monitor/accounts', azureMonitorWorkspace.name)
  }
}
