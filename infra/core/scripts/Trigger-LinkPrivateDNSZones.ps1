<#
.SYNOPSIS
Triggers ADO pipeline to Link DNS Zone to central networks

.DESCRIPTION
This script triggers a pipeline in CCOE-Infrastructure ADO project to link the DNS zone to central networks

.PARAMETER PrivateDnsZoneName
Mandatory. Private DNS Zone Name.

.PARAMETER ResourceGroupName
Mandatory. Private DNS Zone Resource Group Name.

.PARAMETER SubscriptionName
Mandatory. Private DNS Zone Subscription Name.

.PARAMETER TenantId
Mandatory. Private DNS Zone Tenant Id.

.EXAMPLE
.\Trigger-LinkPrivateDNSZones.ps1 -privateDnsZoneName <private Dns Zone Name> -resourceGroupName <dns zone resource group> -subscriptionName <dns zone subscription name> -tenantId <dns zone tenant id>
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory)] 
    [string]$PrivateDnsZoneName,
    [Parameter(Mandatory)] 
    [string]$ResourceGroupName,
    [Parameter(Mandatory)] 
    [string]$SubscriptionName,
    [Parameter(Mandatory)] 
    [string]$TenantId,
    [Parameter]
    [string]$WorkingDirectory = $PWD.Path
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
Write-Debug "${functionName}:PrivateDnsZoneName=$PrivateDnsZoneName"
Write-Debug "${functionName}:ResourceGroupName=$ResourceGroupName"
Write-Debug "${functionName}:SubscriptionName=$SubscriptionName"
Write-Debug "${functionName}:TenantId=$TenantId"
Write-Debug "${functionName}:WorkingDirectory=$WorkingDirectory"

try {
    [System.IO.DirectoryInfo]$moduleDir = Join-Path -Path $WorkingDirectory -ChildPath "scripts/modules/ado"
    Write-Debug "${functionName}:moduleDir.FullName=$($moduleDir.FullName)"
    Import-Module $moduleDir.FullName -Force

    [object]$runPipelineRequestBodyWithDefaultConfig = '{
        "templateParameters": {
            "PrivateDnsZoneName": "",
            "ResourceGroup": "",
            "Subscription": "",
            "Tenant": ""
        }
    }' | ConvertFrom-Json
    $runPipelineRequestBodyWithDefaultConfig.templateParameters.PrivateDnsZoneName = $PrivateDnsZoneName
    $runPipelineRequestBodyWithDefaultConfig.templateParameters.ResourceGroup = $ResourceGroupName
    $runPipelineRequestBodyWithDefaultConfig.templateParameters.Subscription = $SubscriptionName
    $runPipelineRequestBodyWithDefaultConfig.templateParameters.Tenant = $TenantId
    [string]$requestBodyJson = $($runPipelineRequestBodyWithDefaultConfig | ConvertTo-Json)

    New-BuildRun -organisationUri $env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI -projectName "CCoE-Infrastructure" -buildDefinitionId 4634 -requestBody $requestBodyJson

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