@description('The grafana resource name.')
param name string

@description('The Sku of the grafana resource.')
param resourceSku string = 'Standard'

@description('The api key setting of the Grafana instance. Default value is Disabled.')
@allowed([ 'Disabled', 'Enabled' ])
param apiKey string = 'Disabled'

@description('Whether a Grafana instance uses deterministic outbound IPs. Default value is Disabled.')
@allowed([ 'Disabled', 'Enabled' ])
param deterministicOutboundIP string = 'Disabled'

@description('Indicate the state for enable or disable traffic over the public interface. Default value is Disabled.')
@allowed([ 'Disabled', 'Enabled' ])
param publicNetworkAccess string = 'Disabled'

@description('The zone redundancy setting of the Grafana instance. Default value is Disabled.')
@allowed([ 'Disabled', 'Enabled' ])
param zoneRedundancy string = 'Disabled'

@description('The managed service identity type of the Grafana instance. Default value is None.')
@allowed([ 'None', 'SystemAssigned', 'SystemAssigned,UserAssigned', 'UserAssigned' ])
param managedServiceIdentityType string = 'None'

@description('Required. The Azure region where the resources will be deployed.')
param location string

@description('Required. Environment name.')
param environment string

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

@description('The resourceIds of Azure Monitor Workspaces which will be linked to Grafana')
param azureMonitorWorkspaceResourceIds array

var commonTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
  Purpose: 'ADP-GRAFANA-DASHBOARD'
}
var tags = union(loadJsonContent('../default-tags.json'), commonTags)

resource graphanaDashboardResource 'Microsoft.Dashboard/grafana@2022-08-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: resourceSku
  }
  identity: {
    type: managedServiceIdentityType
  }
  properties: {
    apiKey: apiKey
    autoGeneratedDomainNameLabelScope: 'TenantReuse'
    deterministicOutboundIP: deterministicOutboundIP
    grafanaIntegrations: {
      azureMonitorWorkspaceIntegrations: [for azureMonitorWorkspaceResourceId in azureMonitorWorkspaceResourceIds: {
        azureMonitorWorkspaceResourceId: azureMonitorWorkspaceResourceId.workspaceResourceId
      }]
    }
    publicNetworkAccess: publicNetworkAccess
    zoneRedundancy: zoneRedundancy
  }
}

// NEED TO ADD GRAFANA ADMINS ROLE
/*
resource grafanaRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for adoServicePrincipal in adoServicePrincipals: {
  name: guid(resourceGroup().id, 'Contributor', adoServicePrincipal.objectId, adoServicePrincipal.name)
  scope: graphanaDashboardResource
  properties: {
    principalId: adoServicePrincipal.objectId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor
    principalType: 'ServicePrincipal'
  }
}]
*/
