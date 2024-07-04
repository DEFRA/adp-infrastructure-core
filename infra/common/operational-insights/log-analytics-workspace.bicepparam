using 'log-analytics-workspace.bicep'

param logAnalytics = {
  name: '#{{ logAnalyticsWorkspace }}'
  skuName: '#{{ logAnalyticsWorkspaceSku }}'
}

param location = '#{{ location }}'

param environment = '#{{ environment }}'

param resourceLockEnabled = #{{ resourceLockEnabled }}
