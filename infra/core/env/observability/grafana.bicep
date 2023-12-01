@description('Required. The object of the Grafana Dashboard. The object must contain name,publicNetworkAccess and grafanaResourceSku.')
param grafana object

@description('The object ID of the Grafan Admin group')
param grafanaAdminsGroupObjectId string

@description('Required. The Azure region where the resources will be deployed.')
param location string

@description('Required. Environment name.')
param environment string

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

@description('The resourceIds of Azure Monitor Workspaces which will be linked to Grafana')
param azureMonitorWorkspaceResourceIds string

// @description('Required. The parameter object for the monitor workspace. The object must contain the name, subscriptionId and resourceGroup values.')
// param azureMonitorWorkspace object

// @description('Optional. Date in the format yyyyMMdd-HHmmss.')
// param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

var commonTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
  Purpose: 'ADP-GRAFANA-DASHBOARD'
}
var tags = union(loadJsonContent('../../../common/default-tags.json'), commonTags)

var azureMonitorWorkspaceResourceIdObject = [for azureMonitorWorkspaceResourceId in split(azureMonitorWorkspaceResourceIds, ' '): {
  azureMonitorWorkspaceResourceId: azureMonitorWorkspaceResourceId
}]

resource grafanaDashboardResource 'Microsoft.Dashboard/grafana@2022-08-01' = {
  name: grafana.name
  location: location
  tags: tags
  sku: {
    name: grafana.resourceSku
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    grafanaIntegrations: {
      azureMonitorWorkspaceIntegrations: !empty(azureMonitorWorkspaceResourceIds) ? azureMonitorWorkspaceResourceIdObject : null
    }
    publicNetworkAccess: grafana.publicNetworkAccess
  }
}

resource grafanaRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, 'GrafanaAdmin', grafanaAdminsGroupObjectId)
  scope: grafanaDashboardResource
  properties: {
    principalId: grafanaAdminsGroupObjectId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '22926164-76b3-42b3-bc55-97df8dab3e41') // Grafana Admin
    principalType: 'Group'
  }
}

// module monitorWorkspaceRoleAssignment '.bicep/monitoring-reader.bicep' = {
//   name: 'monitor-workspace-monitoring-reader-role-${deploymentDate}'
//   scope: resourceGroup(azureMonitorWorkspace.subscriptionId, azureMonitorWorkspace.resourceGroup)
//   params: {
//     azureMonitorWorkspaceName: azureMonitorWorkspace.name
//     principalId: grafanaDashboardResource.identity.principalId
//   }
// }
