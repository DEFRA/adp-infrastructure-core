@description('The resourceIds of Azure Monitor Workspaces which will be linked to Grafana')
param azureMonitorWorkspaceResourceIds string //= '[{"AzureMonitorWorkspaceResourceId":"/subscriptions/55f3b8c6-6800-41c7-a40d-2adb5e4e1bd1/resourceGroups/SNDCDOINFRG1401/providers/Microsoft.Monitor/accounts/SNDCDOINFMW1401"},{"AzureMonitorWorkspaceResourceId":"/subscriptions/916afc11-9a78-4f8a-91c4-d50754b76733/resourceGroups/SNDCDOINFRG2401/providers/Microsoft.Monitor/accounts/SNDCDOINFMW2401"}]'

var stringtoarray = array(azureMonitorWorkspaceResourceIds)

output testoutput array = stringtoarray
