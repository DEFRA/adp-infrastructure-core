<#
.SYNOPSIS
Sets the secondary event hub address key value pair in app configuration
.DESCRIPTION
Sets the secondary event hub address key value pair in app configuration if SendFluxNotificationsToSecondEventHub is true.
.PARAMETER ImportConfigDataScriptPath
Mandatory. Import Config Data Script Path.
.PARAMETER AppConfigName
Mandatory. App Configuration Name.
.PARAMETER SendFluxNotificationsToSecondEventHub
Mandatory. Send Flux Notifications To Second Event Hub.
.PARAMETER Label
Mandatory. Label.
.PARAMETER ConfigData
Mandatory. Config Data.
.EXAMPLE
.\Set-SecondaryEventHubConfig.ps1 -ImportConfigDataScriptPath <ImportConfigDataScriptPath> -AppConfigName <AppConfigName> -SendFluxNotificationsToSecondEventHub <SendFluxNotificationsToSecondEventHub> -Label <Label> -ConfigData <ConfigData>
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $ImportConfigDataScriptPath,
    [Parameter(Mandatory)]
    [string] $AppConfigName,
    [Parameter(Optional)]
    [string] $SendFluxNotificationsToSecondEventHub = "false",
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
Write-Debug "${functionName}:ImportConfigDataScriptPath=$ImportConfigDataScriptPath"
Write-Debug "${functionName}:AppConfigName=$AppConfigName"
Write-Debug "${functionName}:SendFluxNotificationsToSecondEventHub=$SendFluxNotificationsToSecondEventHub"

try {

    if ($SendFluxNotificationsToSecondEventHub -eq "true") {
        Write-Host "Set location to Import Config Data Script Path..."
        Set-Location $ImportConfigDataScriptPath
    
        Write-Host "Setting Secondary Event Hub Address in App Configuration..."
        ./templates/powershell/Import-ConfigData.ps1 -Label $Label -AppConfigName $AppConfigName -ConfigData $ConfigData
    } else {
        Write-Host "Secondary Event Hub Address is not set required in App Configuration."
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