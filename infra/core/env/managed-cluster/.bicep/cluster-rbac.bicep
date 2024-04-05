@description('Required. The principal id for the managed identity.')
param clusterName string

@description('Required. The principal id for the managed identity.')
param principalId string

resource cluster 'Microsoft.ContainerService/managedClusters@2024-01-01' existing = {
  name: clusterName
}

resource clusterUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, principalId, 'Azure Kubernetes Service Cluster User Role')
  scope: cluster
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4abbcc35-e782-43d8-92c5-2d3f1bd2253f')
    principalId: principalId
    principalType: 'Group'
  }
}

resource clusterRBACReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, principalId, 'Azure Kubernetes Service RBAC Reader')
  scope: cluster
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f6c6a51-bcf8-42ba-9220-52d62157d7db')
    principalId: principalId
    principalType: 'Group'
  }
}
