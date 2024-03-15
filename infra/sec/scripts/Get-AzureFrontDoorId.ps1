<#
.SYNOPSIS
Get Azure FrontDoor ID and pass them to App gateway WAF policy bicep template
.DESCRIPTION
Get Azure FrontDoor ID and set variable with values which are then used by the App gateway WAF policy bicep template.
.PARAMETER ResourceGroupName
Mandatory. Resource Group Name.
.PARAMETER FrontDoorProfileName
Mandatory. FrontDoorProfile Name.
.EXAMPLE
.\Get-AzureFrontDoorId.ps1 -ResourceGroupName <ResourceGroupName> -FrontDoorProfileName <FrontDoorProfileName>
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory)] 
    [string] $ResourceGroupName,
    [Parameter(Mandatory)]
    [string] $FrontDoorProfileName
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
Write-Debug "${functionName}:FrontDoorProfileName=$FrontDoorProfileName"

try {
    if (-not (Get-Module -ListAvailable -Name 'Az.Cdn')) {
        Write-Host "Az.Cdn Module does not exists. Installing now.."
        Install-Module Az.Cdn -Force
        Write-Host "Az.Cdn Installed Successfully."
    

        Write-Host "Getting FrontDoor Profile $FrontDoorProfileName from Resource Group $ResourceGroupName..."
        [object]$fdProfile = Get-AzFrontDoorCdnProfile -ResourceGroupName $ResourceGroupName -Name $FrontDoorProfileName -ErrorAction SilentlyContinue

        if ($fdProfile) {
            Write-host "FrontDoor Profile $FrontDoorProfileName exists in Resource Group $ResourceGroupName"
            Write-Debug "${functionName}:azureFrontDoorProfileFrontDoorId=$($fdProfile.FrontDoorId)"
            Write-Host "##vso[task.setvariable variable=azureFrontDoorProfileFrontDoorId]$($fdProfile.FrontDoorId)"
        }
        else {
            throw "FrontDoor Profile $FrontDoorProfileName does not exists in Resource Group $ResourceGroupNameso, so the FrontDoorId details could not be retrieved."
        }

        $exitCode = 0

    }
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