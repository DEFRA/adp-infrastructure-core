@description('The resourceIds of Azure Monitor Workspaces which will be linked to Grafana')
param azureMonitorWorkspaceResourceIds string

output outputAzureMonitorWorkspaceResourceIds string = azureMonitorWorkspaceResourceIds
