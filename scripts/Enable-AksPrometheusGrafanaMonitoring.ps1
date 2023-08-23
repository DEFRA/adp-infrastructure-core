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

try {
  az aks update --enable-azure-monitor-metrics -n $AksClusterName -g $ResourceGroupName --azure-monitor-workspace-resource-id $AzureMonitorWorkspaceResourceId --grafana-resource-id  $GrafanaResourceId
  #az aks update --enable-azure-monitor-metrics -n fdgfgfdgd -g dgfgdfgfgfd --azure-monitor-workspace-resource-id /subscriptions/<subscriptionId>/resourceGroups/<resourceGroupName>/providers/microsoft.monitor/accounts/<resourceName> --grafana-resource-id  /subscriptions/<subscriptionId>/resourceGroups/<resourceGroupName>/providers/microsoft.dashboard/grafana/<resourceName>
  #if ($? -eq $false) {
  #  throw 'az aks update --enable-azure-monitor-metrics failed.'
  #}
}
catch {
  Write-Error $_.Exception.ToString()
  throw $_.Exception
  #Write-Host "TEST"
}



