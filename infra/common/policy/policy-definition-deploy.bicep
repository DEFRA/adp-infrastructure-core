targetScope = 'subscription'

@description('Required. Array of Diagnostic Setting Policies.')
param policyDefinitions array

@description('Required. Location for all resources.')
param location string

@sys.description('Optional. The Target Scope for the Policy. The subscription ID of the subscription for the policy assignment. If not provided, will use the current scope for deployment.')
param subscriptionId string = subscription().subscriptionId

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

module policyAssignmentModule '.bicep/policy-definition.bicep' = [
  for (policyDefinition, index) in policyDefinitions: {
    name: 'policy-def-${index}-${deploymentDate}'
    params: {
      enableDefaultTelemetry: false
      name: guid(subscriptionId, policyDefinition.displayName)
      location: location
      displayName: policyDefinition.displayName
      description: policyDefinition.description
      policyRule: policyDefinition.policyRule
      parameters: policyDefinition.parameters
    }
  }
]
