@description('Required. The parameter object for the managed identity. The object must contain the name and principalId values.')
param principalId string
@description('Required. The name of the Azure Monitor Workspace')
param azureMonitorWorkspaceName string

resource azureMonitorWorkSpaceResource 'Microsoft.Monitor/accounts@2023-04-03' existing = {
  name: azureMonitorWorkspaceName
}

resource monitorWorkspaceMDRRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, 'MonitoringDataReader', azureMonitorWorkSpaceResource.name)
  scope: azureMonitorWorkSpaceResource
  properties: {
    principalId: principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b0d8363b-8ddd-447d-831f-62ca05bff136') // Monitoring Data Reader
    principalType: 'ServicePrincipal'
  }
}
