<#
.SYNOPSIS
Create a role assignment to subscription scope.

.DESCRIPTION
Assigns RBAC 'User Access Administrator' and 'Contributor' to subscription scope.

.PARAMETER SubscriptionName
Mandatory. Subscription Name.

.PARAMETER KeyVaultName
Mandatory. Keyvault Name.

.PARAMETER Tier2ApplicationClientIdSecretName
Mandatory. Keyvault Secret Name of AAD Application.

.EXAMPLE
.\Set-RBAC-Subscriptions.ps1 -SubscriptionName <SubscriptionName> -KeyVaultName <KeyVaultName> -Tier2ApplicationClientIdSecretName <AAD-Application-ClientId>
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

Function New-RoleAssignment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True)]$Scope,
        [Parameter(Mandatory = $True)]$ObjectId,
        [Parameter(Mandatory = $True)]$RoleDefinitionName
    )

    [string]$functionName = $MyInvocation.MyCommand    
    Write-Debug "${functionName}:Entered"
    Write-Debug "${functionName}:Scope=$Scope"
    Write-Debug "${functionName}:ObjectId=$ObjectId"
    Write-Debug "${functionName}:RoleDefinitionName=$RoleDefinitionName"

    $isRoleAssignmentExist = (Get-AzRoleAssignment -Scope $Scope -RoleDefinitionName $RoleDefinitionName -ObjectId $ObjectId)
    Write-Debug "isRoleAssignmentExist=$isRoleAssignmentExist"

    if (-not $isRoleAssignmentExist) {
        Write-Host "Creating new Role Assignment : RoleDefinitionName = $RoleDefinitionName, Scope = $Scope, ObjectId = $ObjectId"
        New-AzRoleAssignment -Scope $subscriptionScope -RoleDefinitionName $RoleDefinitionName -ObjectId $ObjectId | Out-Null
    }
    else {
        Write-Host "Role Assignment already exist for : RoleDefinitionName = $RoleDefinitionName, Scope = $subscriptionScope, ObjectId = $ObjectId"
    }

    Write-Debug "${functionName}:Exited"
}

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

try {
    Write-Host "Fethcing Client ID $($Tier2ApplicationClientIdSecretName) from KeyVaultName =  $($KeyVaultName)"
    [string]$tier2ApplicationClientId = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $Tier2ApplicationClientIdSecretName -AsPlainText -ErrorAction Stop
    Write-Host "$($Tier2ApplicationClientIdSecretName) = $($tier2ApplicationClientId)"

    if (-not [string]::IsNullOrWhiteSpace($tier2ApplicationClientId)) {
        [System.Object]$context = Set-AzContext -Subscription $SubscriptionName
        [string]$subscriptionID = $context.Subscription.Id
        [string]$subscriptionScope = "/subscriptions/$($subscriptionID)"
        [string]$servicePrincipalObjectID = (Get-AzADServicePrincipal -ApplicationId $tier2ApplicationClientId).Id

        Write-Host "Create User Acess Administrator role assignment.."
        New-RoleAssignment -Scope $subscriptionScope -ObjectId $servicePrincipalObjectID -RoleDefinitionName "User Access Administrator"

        Write-Host "Create Contributor role assignment.."
        New-RoleAssignment -Scope $subscriptionScope -ObjectId $servicePrincipalObjectID -RoleDefinitionName "Contributor"
        $exitCode = 0
    }
    else {
        Write-Error "Could not find ClinetID secret $($Tier2ApplicationClientIdSecretName) in keyvault $($KeyVaultName)"
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