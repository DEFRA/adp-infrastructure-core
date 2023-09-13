<#
.SYNOPSIS
Get Azure Monitor Workspace ResourceIds and pass them to Grafana Dashboard bicep template
.DESCRIPTION
Get Azure Monitor Workspace ResourceIds and set variable with values which are then used by the Grafana Dashboard bicep template.
.PARAMETER ResourceGroupName
Mandatory. Resource Group Name.
.PARAMETER GrafanaName
Mandatory. Grafana Dashboard name.
.PARAMETER WorkspaceResourceId
Mandatory. Azure Monitor Workspace ResourceId.
.EXAMPLE
.\Connect-WorkspaceToGrafana.ps1 -ResourceGroupName <ResourceGroupName> -GrafanaName <GrafanaName> -WorkspaceResourceId <WorkspaceResourceId>
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory)] 
    [string] $ResourceGroupName,
    [Parameter(Mandatory)]
    [string] $GrafanaName,
    [Parameter(Mandatory)]
    [string] $WorkspaceResourceId
)

Set-StrictMode -Version 3.0

[string]$functionName = $MyInvocation.MyCommand
[datetime]$startTime = [datetime]::UtcNow

[int]$exitCode = -1
[bool]$setHostExitCode = (Test-Path -Path ENV:TF_BUILD) -and ($ENV:TF_BUILD -eq "true")
[bool]$enableDebug = (Test-Path -Path ENV:SYSTEM_DEBUG) -and ($ENV:SYSTEM_DEBUG -eq "true")

Set-Variable -Name ErrorActionPreference -Value Continue -scope global
Set-Variable -Name InformationPreference -Value Continue -Scope global

if ($enableDebug) {
    Set-Variable -Name VerbosePreference -Value Continue -Scope global
    Set-Variable -Name DebugPreference -Value Continue -Scope global
}

Write-Host "${functionName} started at $($startTime.ToString('u'))"
Write-Debug "${functionName}:ResourceGroupName=$ResourceGroupName"
Write-Debug "${functionName}:GrafanaName=$GrafanaName"
Write-Debug "${functionName}:WorkspaceResourceId=$WorkspaceResourceId"

try {
    if (-not (Get-Module -ListAvailable -Name 'Az.Dashboard')) {
        Write-Host "Az.Dashboard Module does not exists. Installing now.."
        Install-Module Az.Dashboard -Force
        Write-Host "Az.Dashboard Installed Successfully."
    }

    Write-Host "${functionName}:Getting Grafana Dashboard $GrafanaName from Resource Group $ResourceGroupName..."
    [object]$grafana = Get-AzGrafana -ResourceGroupName $ResourceGroupName -GrafanaName $GrafanaName -ErrorAction SilentlyContinue
    Write-Host "${functionName}:Finished getting Grafana Dashboard"

    [array]$linkedWorkspaces = @()

    if ($null -eq $grafana) {
        $linkedWorkspaces += $WorkspaceResourceId
    }
    else {
        $linkedWorkspacesObjectExists = $($grafana.GrafanaIntegrationAzureMonitorWorkspaceIntegration).psobject.BaseObject -match "azureMonitorWorkspaceResourceId"
        if (-not [string]::IsNullOrEmpty($linkedWorkspacesObjectExists)) {
            $linkedWorkspaces = $grafana.GrafanaIntegrationAzureMonitorWorkspaceIntegration.AzureMonitorWorkspaceResourceId
        }
        Write-Debug "${functionName}:linkedWorkspaces=$linkedWorkspaces"

        [string]$workspaceAlreadyLinked = $linkedWorkspaces -Match "$WorkspaceResourceId"
        if ([string]::IsNullOrEmpty($workspaceAlreadyLinked) -or $workspaceAlreadyLinked -eq 'False') {
            $linkedWorkspaces += $WorkspaceResourceId
        }
    }

    Write-Host "##vso[task.setvariable variable=azureMonitorWorkspaceResourceIds]$linkedWorkspaces"
    Write-Host $linkedWorkspaces
    $exitCode = 0

}
catch {
    $exitCode = -2
    Write-Error $_.Exception.ToString()
    throw $_.Exception
}
finally {
    [DateTime]$endTime = [DateTime]::UtcNow
    [Timespan]$duration = $endTime.Subtract($startTime)

    Write-Host "${functionName} finished at $($endTime.ToString('u')) (duration $($duration -f 'g')) with exit code $exitCode"
    if ($setHostExitCode) {
        Write-Debug "${functionName}:Setting host exit code"
        $host.SetShouldExit($exitCode)
    }
    exit $exitCode
}