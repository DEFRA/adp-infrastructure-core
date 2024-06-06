<#
.SYNOPSIS
Sets the secondary event hub address key value pair in app configuration
.DESCRIPTION
Sets the secondary event hub address key value pair in app configuration 
.PARAMETER ResourceGroupName
Mandatory. Resource Group Name.
.EXAMPLE
.\Set-SecondaryEventHubConfig.ps1 -ResourceGroupName <ResourceGroupName>
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $ImportConfigDataScript,
    [Parameter(Mandatory)]
    [string] $AppConfigName,
    [Parameter(Mandatory)]
    [string] $SendFluxNotificationsToSecondEventHub,
    [Parameter(Mandatory)]
    [string] $Label,
    [Parameter(Mandatory)]
    [string] $ConfigData
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
Write-Debug "${functionName}:ImportConfigDataScript=$ImportConfigDataScript"
Write-Debug "${functionName}:AppConfigName=$AppConfigName"
Write-Debug "${functionName}:SendFluxNotificationsToSecondEventHub=$SendFluxNotificationsToSecondEventHub"

try {

    <#
    {
        "key": "address",
        "value": "{\"uri\":\"https://#{{ ssvEventHub2ConnectionStringKeyVault }}.vault.azure.net/secrets/#{{ environment }}#{{ nc_instance_regionid }}0#{{ environmentId }}-ADP-EVENTHUB-CONNECTION\"}",
        "label": "adp-platform-secondary-eventhub",
        "contentType": "text/plain"
    }
    #>
    if ($SendFluxNotificationsToSecondEventHub -eq "true") {
        Set-Location $ImportConfigDataScript
    
        Write-Host "Setting Secondary Event Hub Address in App Configuration..."

        ./templates/powershell/Import-ConfigData.ps1 -Label $Label -AppConfigName $AppConfigName -ConfigData $ConfigData
        # ./templates/powershell/Import-ConfigData.ps1 -Label "testaa" -AppConfigName $AppConfigName -ConfigData '[{"key": "TESTAA", "value": "TESTVALUE", "label": "testaa", "contentType": "text/plain" }]'
    } else {
        Write-Host "Secondary Event Hub Address is not set in App Configuration for $Environment environment"
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