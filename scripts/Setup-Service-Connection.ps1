<#
.SYNOPSIS
Create an Azure RM type service endpoint (ServiceConnection).

.DESCRIPTION
Create an Azure RM type service endpoint (ServiceConnection).

.PARAMETER TenantId
Mandatory. Tenant id for creating azure rm service endpoint.

.PARAMETER SubscriptionId
Mandatory. Subscription id for azure rm service endpoint.

.PARAMETER SubscriptionName
Mandatory. Name of azure subscription for azure rm service endpoint.

.PARAMETER ServiceConnectionAppRegName
Mandatory. Name of the AAD App reg that will be used to create azure rm service endpoint (ServiceConnection).

.PARAMETER KeyVaultName
Mandatory. Keyvault Name where AAD App reg's ClientId and clientSecret is stored.

.PARAMETER DevopsOrgnization
Optional. Azure DevOps organization URL

.PARAMETER DevopsProjectName
Optional. Name or ID of the project

.EXAMPLE
.\Setup-Service-Connection.ps1 -TenantId <TenantId> -SubscriptionId <SubscriptionId> -SubscriptionName <SubscriptionName> -SubscriptionId <SubscriptionId> -KeyVaultName <KeyVaultName>
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory)] 
    [string] $TenantId,
    [Parameter(Mandatory)] 
    [string] $SubscriptionId,
    [Parameter(Mandatory)] 
    [string] $SubscriptionName,
    [Parameter(Mandatory)]
    [string] $ServiceConnectionAppRegName,
    [Parameter(Mandatory)]
    [string] $KeyVaultName,
    [Parameter(Mandatory = $false)]
    [string] $DevopsOrgnization = $env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI,
    [Parameter(Mandatory = $false)]
    [string] $DevopsProjectName = $env:SYSTEM_TEAMPROJECTID
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
Write-Debug "${functionName}:TenantId=$TenantId"
Write-Debug "${functionName}:SubscriptionId=$SubscriptionId"
Write-Debug "${functionName}:SubscriptionName=$SubscriptionName"
Write-Debug "${functionName}:ServiceConnectionAppRegName=$ServiceConnectionAppRegName"
Write-Debug "${functionName}:KeyVaultName=$KeyVaultName"
Write-Debug "${functionName}:DevopsOrgnization=$DevopsOrgnization"
Write-Debug "${functionName}:DevopsProjectName=$DevopsProjectName"

try {
    
    $kvClientIdSecretName = "$ServiceConnectionAppRegName-ClientId"
    $kvClientPasswordSecretName = $ServiceConnectionAppRegName
    $ServiceEndpointName = $SubscriptionName
    
    Write-Host "Fetching Keyvault secret $($kvClientIdSecretName) from $($KeyVaultName)"
    $spClientId = az keyvault secret show --name $kvClientIdSecretName --vault-name $KeyVaultName --query "value" -o tsv
    Write-Debug "spClientId=$spClientId"

    Write-Host "Fetching Keyvault secret $($kvClientPasswordSecretName) from $($KeyVaultName)"
    $spClientPassword = az keyvault secret show --name $kvClientPasswordSecretName --vault-name $KeyVaultName --query "value" -o tsv

    # Set PAT as an environment variable for DevOps Login
    # $env:AZURE_DEVOPS_EXT_PAT = $env:SYSTEM_ACCESSTOKEN

    # #Set Service Principal Secret as an Environment Variable for creating Azure DevOps Service Connection
    $env:AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY = $spClientPassword

    az devops configure --defaults organization=$DevopsOrgnization project=$DevopsProjectName

    Write-Debug "Check if $($ServiceEndpointName) exists"
    $isServiceEndpointAlreadyExist = az devops service-endpoint list --query "[?name=='$ServiceEndpointName'].name" -o tsv
    Write-Debug "isServiceEndpointAlreadyExist=$isServiceEndpointAlreadyExist"

    if (-not $isServiceEndpointAlreadyExist) {
        Write-Host "Creating ServiceEndpointName $($ServiceEndpointName).."
        # Create DevOps Service Connection:-
        az devops service-endpoint azurerm create --azure-rm-service-principal-id $spClientId --azure-rm-subscription-id $SubscriptionId --azure-rm-subscription-name $SubscriptionName --azure-rm-tenant-id $TenantId --name $ServiceEndpointName --org $DevopsOrgnization --project $DevopsProjectName
    }
    else {
        Write-Host "ServiceEndpointName $ServiceEndpointName already exist."
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