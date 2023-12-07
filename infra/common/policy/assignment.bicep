targetScope = 'subscription'

@description('Required. Array of Policy Assignments.')
param policyAssignments array

@description('Required. Log Analytics workspace object. Must have the following properties: name, resourceGroupName')
param logAnalyticsWorkspace object

@description('Required. Location for all resources.')
param location string = 'uksouth'

@sys.description('Optional. The Target Scope for the Policy. The subscription ID of the subscription for the policy assignment. If not provided, will use the current scope for deployment.')
param subscriptionId string = subscription().subscriptionId

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

module policyAssignmentModule '.bicep/policy-assignment.bicep' = [for (policyAssignment,index) in policyAssignments: {
  name: 'policy-definition-${index}-${deploymentDate}'  
  params: {
    name: guid(subscriptionId,policyAssignment.assignmentDisplayName)
    subscriptionId: subscriptionId
    displayName: policyAssignment.assignmentDisplayName
    policyDefinitionId: tenantResourceId('Microsoft.Authorization/policyDefinitions', policyAssignment.policyDefinitionId)
    parameters: {
      logAnalytics:{
        value:  resourceId(logAnalyticsWorkspace.resourceGroupName, 'Microsoft.OperationalInsights/workspaces', logAnalyticsWorkspace.name)
      }
    }
    roleDefinitionIds: [
      '/providers/Microsoft.Authorization/roleDefinitions/749f88d5-cbae-40b8-bcfc-e573ddc772fa'
      '/providers/Microsoft.Authorization/roleDefinitions/92aaf0da-9dab-42b6-94a3-d43ce8d16293'
    ]
    identity: 'SystemAssigned'
    location: location
    enableDefaultTelemetry: false
  }
}]


