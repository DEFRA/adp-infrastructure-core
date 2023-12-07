<#
.SYNOPSIS
Create Flux folder in Grafana and add new dashboards for flux cluster stats and flux control plane
.DESCRIPTION
Creates a Flux folder in Grafana and adds new dashboards for flux cluster stats and flux control plane.
.PARAMETER ResourceGroupName
Mandatory. Resource Group Name.
.PARAMETER GrafanaName
Mandatory. Grafana Dashboard name.
.PARAMETER DashboardsPath
Mandatory. Path to Dashboards directory containing Dashboards json files.
.EXAMPLE
.\New-FluxDashboards.ps1 -ResourceGroupName <ResourceGroupName> -GrafanaName <GrafanaName> -DashboardsPath <DashboardsPath>
#> 

[CmdletBinding()]
param(
[Parameter(Mandatory)]
[string] $GrafanaName,
[Parameter(Mandatory)]
[string] $ResourceGroupName,
[Parameter(Mandatory)]
[string] $DashboardsPath,
[Parameter()]
[string]$WorkingDirectory = $PWD
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
Write-Debug "${functionName}:DashboardsPath=$DashboardsPath"

try {

    [System.IO.DirectoryInfo]$moduleDir = Join-Path -Path $WorkingDirectory -ChildPath "scripts/modules/ps-helpers"
    Write-Debug "${functionName}:moduleDir.FullName=$($moduleDir.FullName)"
    Import-Module $moduleDir.FullName -Force
    
    Write-Host "Add azure managed grafana extension"
    Invoke-CommandLine -Command "az extension add --upgrade -n amg"
    Write-Host "Added extension"

    [string]$fluxFolderName = 'Flux'
    [string]$folderExistsJson = Invoke-CommandLine -Command "az grafana folder list --name $GrafanaName --query ""[?@.title == '$fluxFolderName']"""
    [object]$folderExists = $folderExistsJson | ConvertFrom-Json
    if ([string]::IsNullOrEmpty($folderExists)) {
        Write-Host "Creating new folder $fluxFolderName in Grafana"
        Invoke-CommandLine -Command "az grafana folder create --name $GrafanaName --title $fluxFolderName"
        Write-Host "Created new folder"
    }

    [array]$fluxDashboards = @(
        @{fileName="flux-cluster-stats.json";dashBoardTitle="Flux Cluster Stats"}
        @{fileName="flux-control-plane.json";dashBoardTitle="Flux Control Plane"}
        @{fileName="flux-application-deployments.json";dashBoardTitle="GitOps Flux - Application Deployments Dashboard"}
    )
    [string]$dashBoardExistsJson = Invoke-CommandLine -Command "az grafana dashboard list --name $GrafanaName --resource-group $ResourceGroupName --query ""[?@.folderTitle == '$fluxFolderName']"""
    [object]$dashBoardExists = $dashBoardExistsJson | ConvertFrom-Json

    foreach ($fluxDashboard in $fluxDashboards) {
        if ([string]::IsNullOrEmpty($dashBoardExists) -or $dashBoardExists.title -notcontains $fluxDashboard.dashBoardTitle) {
            [string]$fluxDashboardPath = Join-Path -Path $DashboardsPath -ChildPath $fluxDashboard.fileName
            Write-Host "Creating $($fluxDashboard.fileName) dashboard in Grafana"
            Invoke-CommandLine -Command "az grafana dashboard import --name $GrafanaName --resource-group $ResourceGroupName --definition @$fluxDashboardPath --folder $fluxFolderName"
            Write-Host "Created dashboard in Grafana"
        }
    }

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