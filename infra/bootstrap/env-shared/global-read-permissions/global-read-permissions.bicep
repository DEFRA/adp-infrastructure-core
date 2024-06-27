@description('Required. The principal ID of the group to assign the role to.')
param principalId string

resource roleAssignmentSubscription 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, principalId, 'grafanaViewer')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '60921a7e-fef1-4a43-9b16-a26c52ad4769') // Grafana Viewer
    principalId: principalId
    principalType: 'Group'
  }
}
