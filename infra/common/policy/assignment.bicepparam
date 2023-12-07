using './assignment.bicep'

param policyAssignments = []
param logAnalyticsWorkspace = {
  name: 'myLogAnalyticsWorkspace'
  resourceGroupName:
}
param location = '#{{ location }}'


