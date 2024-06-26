<#
.SYNOPSIS
Get Entra Group Object ID and pass it to bicep template to grant permissions to the group.
.DESCRIPTION
Get Entra Group Object ID and set variable with values which are then used by the bicep template.
.PARAMETER EntraGroupName
Mandatory. Entra Group Name.

.EXAMPLE
.\Get-EntraGroupObjectId.ps1 -EntraGroupName <EntraGroupName>
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory)] 
    [string] $EntraGroupName
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
Write-Debug "${functionName}:EntraGroupName=$EntraGroupName"

try {
    $groupObjectId = Get-AzADGroup -Filter "DisplayName eq '$EntraGroupName'" | Select-Object -ExpandProperty Id

    if ($groupObjectId) {
        $groupId = $group.ObjectId
        Write-Host "##vso[task.setvariable variable=globalReadGroupObjectId]$groupId"
    }
    else {
        Write-Host "Object ID not found."
        $exitCode = -1
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