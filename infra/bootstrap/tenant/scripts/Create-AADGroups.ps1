<#
.SYNOPSIS
Create or Update an Azure AD security Group.

.DESCRIPTION
Create or Update an Azure AD security Group properties, members and owners.

.PARAMETER AADGroupsJsonManifestPath
Mandatory. AAD Groups configuration file.

.PARAMETER WorkingDirectory
Optional. Working directory. Default is $PWD.

.EXAMPLE
.\Create-AADGroups.ps1 AADGroupsJsonManifestPath <AAD Groups config json path>
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory)] 
    [string]$AADGroupsJsonManifestPath,
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
Write-Debug "${functionName}:AADGroupsJsonManifestPath=$AADGroupsJsonManifestPath"
Write-Debug "${functionName}:WorkingDirectory=$WorkingDirectory"

try {
    Write-Host "Script is in progress......"
    [PSCustomObject]$aadGroups = Get-Content -Raw -Path $AADGroupsJsonManifestPath | ConvertFrom-Json
    Write-Debug "${functionName}:aadGroups=$($aadGroups | ConvertTo-Json -Depth 10)"
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