using './policy-diagnostic-settings-assignment.bicep'

param diagnosticPolicies = array(json('#{{ diagnosticSettingsPolicies }}'))
param logAnalyticsWorkspace = {
  name: '#{{ logAnalyticsWorkspace }}'
  resourceGroupName: '#{{ servicesResourceGroup}}'
}
param location = '#{{ location }}'


