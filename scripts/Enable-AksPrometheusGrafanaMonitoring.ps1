param(
  [Parameter(Mandatory = $True)]
  [string]$ResourceGroupName,
  [Parameter(Mandatory = $True)]
  [string]$AksClusterName,
  [Parameter(Mandatory = $True)]
  [string]$AzureMonitorWorkspaceResourceId,
  [Parameter(Mandatory = $True)]
  [string]$GrafanaResourceId
)

az aks update --enable-azure-monitor-metrics -n $AksClusterName -g $ResourceGroupName --azure-monitor-workspace-resource-id $AzureMonitorWorkspaceResourceId --grafana-resource-id  $GrafanaResourceId



