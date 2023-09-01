<#
.SYNOPSIS
Triggers ADO pipeline to Link DNS Zone to central networks

.DESCRIPTION
This script triggers the Auto-LinkPrivateDNSZonesToCentralVNets ADO pipeline

.PARAMETER ServiceEndpointJsonPath
Mandatory. Service connection configuration file.

.PARAMETER WorkingDirectory
Optional. Working directory. Default is $PWD.

.EXAMPLE
.\Initialize-ServiceEndpoint.ps1 -ServiceEndpointJsonPath <Service endpoint config json path>
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory)] 
    [string]$privateDnsZoneName,
    [Parameter(Mandatory)] 
    [string]$resourceGroupName,
    [Parameter(Mandatory)] 
    [string]$subscriptionName,
    [Parameter(Mandatory)] 
    [string]$tenantId
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
Write-Debug "${functionName}:privateDnsZoneName=$privateDnsZoneName"
Write-Debug "${functionName}:resourceGroupName=$resourceGroupName"
Write-Debug "${functionName}:subscriptionName=$subscriptionName"
Write-Debug "${functionName}:tenantId=$tenantId"

try {
    [System.IO.DirectoryInfo]$scriptDir = $PSCommandPath | Split-Path -Parent
    Write-Debug "${functionName}:scriptDir.FullName=$scriptDir.FullName"

    [System.IO.DirectoryInfo]$moduleDir = Join-Path -Path $scriptDir.FullName -ChildPath "modules/ado"
    Write-Debug "${functionName}:moduleDir.FullName=$($moduleDir.FullName)"
    Import-Module $moduleDir.FullName -Force

    [System.IO.DirectoryInfo]$scriptDir = $PSCommandPath | Split-Path -Parent
    Write-Debug "${functionName}:scriptDir.FullName=$scriptDir.FullName"

    [System.IO.DirectoryInfo]$moduleDir = Join-Path -Path $scriptDir.FullName -ChildPath "modules/ps-helpers"
    Write-Debug "${functionName}:moduleDir.FullName=$($moduleDir.FullName)"
    Import-Module $moduleDir.FullName -Force

    [object]$runPipelineRequestBodyWithDefaultConfig = '{
        "variables": {},
        "templateParameters": {
            "PrivateDnsZoneName": "",
            "ResourceGroup": "",
            "Subscription": "",
            "Tenant": ""
        }
    }' | ConvertFrom-Json
    $runPipelineRequestBodyWithDefaultConfig.templateParameters.PrivateDnsZoneName = $privateDnsZoneName
    $runPipelineRequestBodyWithDefaultConfig.templateParameters.ResourceGroup = $resourceGroupName
    $runPipelineRequestBodyWithDefaultConfig.templateParameters.Subscription = $subscriptionName
    $runPipelineRequestBodyWithDefaultConfig.templateParameters.Tenant = $tenantId
    [string]$requestBodyJson = $runPipelineRequestBodyWithDefaultConfig | ConvertTo-Json -Depth 100

    New-BuildRun -OrganisationName $env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI -projectName "CCoE-Infrastructure" -buildDefinitionId 4634 -requestBody $requestBodyJson

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