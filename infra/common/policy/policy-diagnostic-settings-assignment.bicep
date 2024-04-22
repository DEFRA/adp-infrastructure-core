targetScope = 'subscription'

@description('Required. Array of Diagnostic Setting Policies.')
param diagnosticPolicies array

@description('Required. Log Analytics workspace object. Must have the following properties: name, resourceGroupName')
param logAnalyticsWorkspace object 

@description('Required. Location for all resources.')
param location string

@sys.description('Optional. The Target Scope for the Policy. The subscription ID of the subscription for the policy assignment. If not provided, will use the current scope for deployment.')
param subscriptionId string = subscription().subscriptionId

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

var resourceType = 'Microsoft.Authorization/policyDefinitions'

module policyAssignmentModule '.bicep/policy-assignment.bicep' = [for (policyAssignment, index) in diagnosticPolicies: {
  name: 'policy-definition-${index}-${deploymentDate}'
  params: {
    name: guid(subscriptionId, policyAssignment.assignmentDisplayName)
    subscriptionId: subscriptionId
    displayName: policyAssignment.assignmentDisplayName
    policyDefinitionId: ((contains(policyAssignment,'policyDefinitionScope') ? policyAssignment.policyDefinitionScope : 'tenant') == 'subscription')?  subscriptionResourceId(subscriptionId, resourceType, policyAssignment.policyDefinitionId) : tenantResourceId(resourceType, policyAssignment.policyDefinitionId)
    parameters: {
      categoryGroup: {
        value: 'allLogs'
      }
      logAnalytics: {
        value: resourceId(subscriptionId, logAnalyticsWorkspace.resourceGroupName, 'Microsoft.OperationalInsights/workspaces', logAnalyticsWorkspace.name)
      }
    }
    roleDefinitionIds: [
      '/providers/Microsoft.Authorization/roleDefinitions/92aaf0da-9dab-42b6-94a3-d43ce8d16293' // Log Analytics Contributor
    ]
    identity: 'SystemAssigned'
    location: location
    enableDefaultTelemetry: false
  }
}]
