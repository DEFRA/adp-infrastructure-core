<#
.SYNOPSIS
Triggers ADO pipeline to Link DNS Zone to central networks

.DESCRIPTION
This script triggers a pipeline in CCOE-Infrastructure ADO project to link the DNS zone to central networks

.PARAMETER PrivateDnsZoneName
Mandatory. Private DNS Zone Name.

.PARAMETER SubscriptionName
Mandatory. Private DNS Zone Subscription Name.

.PARAMETER TenantId
Mandatory. Private DNS Zone Tenant Id.

.PARAMETER PeerToSec
Optional. Peer to sec vnet. Defaults to false

.EXAMPLE
.\Trigger-VNetPeering.ps1 -VirtualNetworkName <private Dns Zone Name> -SubscriptionName <dns zone subscription name> -TenantId <dns zone tenant id> -PeerToSec <Peer to sec vnet    >
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory)] 
    [string]$VirtualNetworkName,
    [Parameter(Mandatory)] 
    [string]$SubscriptionName,
    [Parameter(Mandatory)] 
    [string]$TenantId,
    [Parameter()]
    [string]$WorkingDirectory = $PWD,
    [Parameter()]
    [bool]$PeerToSec = $false
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
Write-Debug "${functionName}:VirtualNetworkName=$VirtualNetworkName"
Write-Debug "${functionName}:SubscriptionName=$SubscriptionName"
Write-Debug "${functionName}:TenantId=$TenantId"
Write-Debug "${functionName}:WorkingDirectory=$WorkingDirectory"
Write-Debug "${functionName}:PeerToSec=$PeerToSec"

try {
    [System.IO.DirectoryInfo]$moduleDir = Join-Path -Path $WorkingDirectory -ChildPath "scripts/modules/ado"
    Write-Debug "${functionName}:moduleDir.FullName=$($moduleDir.FullName)"
    Import-Module $moduleDir.FullName -Force

    [object]$runPipelineRequestBodyWithDefaultConfig = '{
        "templateParameters": {
            "VirtualNetworkName": "",
            "Subscription": "",
            "Tenant": "",
            "PeerToSec": ""
        }
    }' | ConvertFrom-Json
    $runPipelineRequestBodyWithDefaultConfig.templateParameters.VirtualNetworkName = $VirtualNetworkName
    $runPipelineRequestBodyWithDefaultConfig.templateParameters.Subscription = $SubscriptionName
    $runPipelineRequestBodyWithDefaultConfig.templateParameters.Tenant = $TenantId
    $runPipelineRequestBodyWithDefaultConfig.templateParameters.PeerToSec = $PeerToSec
    [string]$requestBodyJson = $($runPipelineRequestBodyWithDefaultConfig | ConvertTo-Json)

    New-BuildRun -organisationUri $env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI -projectName "CCoE-Infrastructure" -buildDefinitionId 1851 -requestBody $requestBodyJson

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