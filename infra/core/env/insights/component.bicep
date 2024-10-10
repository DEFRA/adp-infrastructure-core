@description('Required. The parameter object for servicebus. The object must contain the name and workspaceName values.')
param appInsights object

@description('Required. Disable key only based Authentication.')
param disableLocalAuth bool = false

@description('Optional. The Azure region where the resources will be deployed.')
param location string = resourceGroup().location

@description('Required. Environment name.')
param environment string

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

@description('Required. monitoringPublisherGroup id.')
param monitoringPublisherGroup string

var roleAssignments = [
  {
    roleDefinitionIdOrName: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '3913510d-42f4-4e42-8a64-420c390055eb') // Monitoring Metrics Publisher
    description: 'Monitoring Metrics Publisher Role Assignment'
    principalId: monitoringPublisherGroup
    principalType: 'Group'
  }
  {
    roleDefinitionIdOrName: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7') // Reader
    description: 'Reader Role Assignment'
    principalId: monitoringPublisherGroup
    principalType: 'Group'
  }
]

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
  Name: appInsights.name
  Purpose: 'Application Insights'
  Tier: 'Shared'
}
var tags = union(loadJsonContent('../../../common/default-tags.json'), customTags)

module appInsightsResource 'br/avm:insights/component:0.3.0' = {
  name: 'app-insights-${deploymentDate}'
  params: {
    name: appInsights.name
    workspaceResourceId: resourceId('Microsoft.OperationalInsights/workspaces', appInsights.workspaceName)
    roleAssignments: roleAssignments
    disableLocalAuth: disableLocalAuth
    location: location
    tags: tags
  }
}
