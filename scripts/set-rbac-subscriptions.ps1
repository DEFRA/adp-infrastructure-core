<#
.SYNOPSIS
Create a role assignment to subscription scope.

.DESCRIPTION
Assigns RBAC 'User Access Administrator' and  'Contributor' to subscription scope.

.PARAMETER SubscriptionName
Mandatory. Subscription Name for e.g. AZD-CDO-SND1.

.PARAMETER KeyVaultName
Mandatory. Keyvault Name.

.PARAMETER Tier2ApplicationClientIdSecretName
Mandatory. Keyvault Secret Name of AAD Application.

.EXAMPLE
.\set-rbac-subscriptions.ps1 -SubscriptionName 'AZD-CDO-SND1' -KeyVaultName 'SNDCDOINFKV1401' -Tier2ApplicationClientIdSecretName 'ADO-DefraGovUK-CDO-SND1-Cont-ClientId'
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory)] 
    [string] $SubscriptionName,
    [Parameter(Mandatory)]
    [string] $KeyVaultName,
    [Parameter(Mandatory)]
    [string] $Tier2ApplicationClientIdSecretName
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
Write-Debug "${functionName}:SubscriptionName=$SubscriptionName"
Write-Debug "${functionName}:KeyVaultName=$KeyVaultName"
Write-Debug "${functionName}:Tier2ApplicationClientIdSecretName=$Tier2ApplicationClientIdSecretName"

# sourcing helper function
. $PSScriptRoot\helper-functions.ps1

try {
    Write-Host "Fethcing Client ID $($Tier2ApplicationClientIdSecretName) from KeyVaultName =  $($KeyVaultName)"
    $tier2ApplicationClientId = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $Tier2ApplicationClientIdSecretName -AsPlainText -ErrorAction Stop
    Write-Host "$($Tier2ApplicationClientIdSecretName) = $($tier2ApplicationClientId)"

    if (-not [string]::IsNullOrWhiteSpace($tier2ApplicationClientId)) {
        Set-AzContext -Subscription $SubscriptionName
        $subscriptionID = (Get-AzContext).Subscription.Id
        $subscriptionScope = "/subscriptions/$($subscriptionID)"
        $servicePrincipalObjectID = (Get-AzADServicePrincipal -ApplicationId $tier2ApplicationClientId).Id

        Write-Host "Create User Acess Administrator role assignment.."
        New-RoleAssignment -Scope $subscriptionScope -ObjectId $servicePrincipalObjectID -RoleDefinitionName "User Access Administrator"

        Write-Host "Create Contributor role assignment.."
        New-RoleAssignment -Scope $subscriptionScope -ObjectId $servicePrincipalObjectID -RoleDefinitionName "Contributor"
    }
    else {
        Write-Error "Could not find ClinetID secret $($Tier2ApplicationClientIdSecretName) in keyvault $($KeyVaultName)"
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