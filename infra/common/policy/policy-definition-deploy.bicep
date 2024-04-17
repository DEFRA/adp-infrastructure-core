targetScope = 'subscription'

@description('Required. Array of Diagnostic Setting Policies.')
param policyDefinitions array

@description('Required. Location for all resources.')
param location string

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

module policyAssignmentModule '.bicep/policy-definition.bicep' = [
  for (policyDefinition, index) in policyDefinitions: {
    name: 'policy-def-${index}-${deploymentDate}'
    params: {
      enableDefaultTelemetry: false
      name: policyDefinition.displayName
      location: location
      displayName: policyDefinition.displayName
      description: policyDefinition.description
      policyRule: policyDefinition.policyRule
      parameters: policyDefinition.parameters
    }
  }
]
