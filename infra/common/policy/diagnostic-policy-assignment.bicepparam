using './assignment.bicep'

param diagnosticPolicies = [
  {
    assignmentDisplayName: 'Deploy - Configure diagnostic settings for Azure Key Vault to Log Analytics workspace'
    policyDefinitionId: '951af2fa-529b-416e-ab6e-066fd85ac459'
  }
]
param logAnalyticsWorkspace = {
  name: '#{{ logAnalyticsWorkspace }}'
  resourceGroupName: '#{{ servicesResourceGroup}}'
}
param location = '#{{ location }}'


