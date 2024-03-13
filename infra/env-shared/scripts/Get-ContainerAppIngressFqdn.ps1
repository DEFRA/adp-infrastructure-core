<#
.SYNOPSIS
Get Container App IngressFqdn and pass them to App gateway bicep template
.DESCRIPTION
Get Container App IngressFqdn and set variable with values which are then used by the App gateway bicep template to setup backendpool.
.PARAMETER ResourceGroupName
Mandatory. Resource Group Name.
.PARAMETER ContainerAppName
Mandatory. ContainerAppName Name.
.EXAMPLE
.\Get-ContainerAppIngressFqdn.ps1 -ResourceGroupName <ResourceGroupName> -ContainerAppName <ContainerAppName>
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory)] 
    [string] $ResourceGroupName,
    [Parameter(Mandatory)]
    [string] $ContainerAppName
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
Write-Debug "${functionName}:ContainerAppName=$ContainerAppName"

try {
    if (-not (Get-Module -ListAvailable -Name 'Az.App')) {
        Write-Host "Az.App Module does not exists. Installing now.."
        Install-Module Az.App -Force
        Write-Host "Az.App Installed Successfully."
    

    Write-Host "Getting ContainerApp $ContainerAppName from Resource Group $ResourceGroupName..."
    [object]$containerapp = Get-AzContainerApp -ResourceGroupName $ResourceGroupName -Name $ContainerAppName -ErrorAction SilentlyContinue

    if($containerapp){
        Write-host "ContainerApp $ContainerAppName exists in Resource Group $ResourceGroupName"
        Write-Debug "${functionName}:containerAppIngressFqdn=$($containerapp.Configuration.IngressFqdn)"
        Write-Host "##vso[task.setvariable variable=containerAppIngressFqdn]$($containerapp.Configuration.IngressFqdn)"
    }
    else{
        throw "ContainerApp $ContainerAppName does not exists in Resource Group $ResourceGroupNameso, so the IngressFqdn details could not be retrieved."
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