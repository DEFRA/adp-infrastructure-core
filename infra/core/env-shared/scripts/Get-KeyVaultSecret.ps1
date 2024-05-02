<#
.SYNOPSIS
Get keyvault secret.

.DESCRIPTION
Get keyvault secret and store it in task variable

.PARAMETER KeyVaultName
Mandatory. KeyVault Name.

.PARAMETER -SecretName
Mandatory. Secret Name.

.PARAMETER TaskVariableName
Mandatory. Task Variable Name.

.EXAMPLE
.\Set-RoleAssignments KeyVaultName <KeyVaultName> -SecretName <SecretName> -TaskVariableName <TaskVariableName>
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory)] 
    [string]$KeyVaultName,
    [Parameter(Mandatory)] 
    [string]$SecretName,
    [Parameter(Mandatory)] 
    [string]$TaskVariableName
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
Write-Debug "${functionName}:KeyVaultName=$KeyVaultName"
Write-Debug "${functionName}:SecretName=$SecretName"
Write-Debug "${functionName}:TaskVariableName=$TaskVariableName"

try {

    Write-Host "Fetching Keyvault secret $($SecretName) from KeyVaultName $($KeyVaultName)"
    [string]$secretValue = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName -AsPlainText -ErrorAction Stop

    #Write-Host "##vso[task.setvariable variable=API-AUTH-BACKEND-APP-REG-CLIENT-ID]$($secretValue)"
    Write-Host "##vso[task.setvariable variable=$(TaskVariableName)]$($secretValue)"

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