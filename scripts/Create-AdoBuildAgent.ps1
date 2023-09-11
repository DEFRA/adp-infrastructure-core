<#
.SYNOPSIS
Create Virtual Machine Scale-set
.DESCRIPTION
Create Virtual Machine Scale-set for private build agent using image from the shared compute gallery.
.PARAMETER imageGalleryTenantId
Mandatory. Image Gallery Tenant Id.
.PARAMETER tenantId
Mandatory. Tenant Id.
.PARAMETER subscriptionName
Mandatory. Subscription Name.
.PARAMETER resourceGroup
Mandatory. Resource Group Name.
.PARAMETER vmssName
Mandatory. Virtual Machine Scale-Set name.
.PARAMETER subnetId
Mandatory. Subnet ResourceId.
.PARAMETER imageId
Mandatory. Shared Gallery Image Reference Id.
.PARAMETER adoAgentUser
Mandatory. VM instance login user name.
.PARAMETER adoAgentPass
Mandatory. VM instance login password.
.EXAMPLE
.\Create-AdoBuildAgent.ps1  -imageGalleryTenantId <imageGalleryTenantId> -tenantId <tenantId> -subscriptionName <subscriptionName> -resourceGroup <resourceGroup> `
                            -vmssName <vmssName> -subnetId <subnetId> -imageId <imageId> -adoAgentUser <adoAgentUser> -adoAgentPass <adoAgentPass>
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $imageGalleryTenantId,
    [Parameter(Mandatory)]
    [string] $tenantId,
    [Parameter(Mandatory)]
    [string] $subscriptionName,
    [Parameter(Mandatory)]
    [string] $resourceGroup,
    [Parameter(Mandatory)]
    [string] $vmssName,
    [Parameter(Mandatory)]
    [string] $subnetId,
    [Parameter(Mandatory)]
    [string] $imageId,
    [Parameter(Mandatory)]
    [string] $adoAgentUser,
    [Parameter(Mandatory)]
    [string] $adoAgentPass
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
Write-Debug "${functionName}:imageGalleryTenantId=$imageGalleryTenantId"
Write-Debug "${functionName}:tenantId=$tenantId"
Write-Debug "${functionName}:subscriptionName=$subscriptionName"
Write-Debug "${functionName}:resourceGroup=$resourceGroup"
Write-Debug "${functionName}:vmssName=$vmssName"
Write-Debug "${functionName}:subnetId=$subnetId"
Write-Debug "${functionName}:imageId=$imageId"

try {
    [System.IO.DirectoryInfo]$scriptDir = $PSCommandPath | Split-Path -Parent
    Write-Debug "${functionName}:scriptDir.FullName=$scriptDir.FullName"

    [System.IO.DirectoryInfo]$moduleDir = Join-Path -Path $scriptDir.FullName -ChildPath "modules/ps-helpers"
    Write-Debug "${functionName}:moduleDir.FullName=$($moduleDir.FullName)"
    Import-Module $moduleDir.FullName -Force

    [string]$command = "az account clear"
    Invoke-CommandLine -Command $command | Out-Null
    
    if ($imageGalleryTenantId -ne $tenantId) {
        $command = "az login --service-principal -u $($env:servicePrincipalId) -p $($env:servicePrincipalKey) --tenant $imageGalleryTenantId"
        Invoke-CommandLine -Command $command | Out-Null
        $command = "az account get-access-token"
        Invoke-CommandLine -Command $command | Out-Null
    }

    $command = "az login --service-principal -u $($env:servicePrincipalId) -p $($env:servicePrincipalKey) --tenant $tenantId"
    Invoke-CommandLine -Command $command | Out-Null
    $command = "az account get-access-token"
    Invoke-CommandLine -Command $command | Out-Null

    $command = "az account set --subscription $subscriptionName"
    Invoke-CommandLine -Command $command | Out-Null

    Write-Host "Checking if the VMSS $vmssName already exists..."
    $command = "az vmss list --resource-group $resourceGroup"
    [string]$commandOutput = Invoke-CommandLine -Command $command

    $instances = $commandOutput | ConvertFrom-Json
    if ($instances -and $instances.count -gt 0 -and ($instances.name -contains $vmssName)) {
        Write-Host "VMSS: $vmssName already exists!"
    }
    else {
        Write-Host "Creating VMSS: $vmssName..."
        
        $command = @"
            az vmss create ``
            --resource-group $resourceGroup ``
            --name $vmssName ``
            --computer-name-prefix $vmssName ``
            --vm-sku Standard_D4s_v4 ``
            --instance-count 2 ``
            --subnet '$subnetId' ``
            --image '$imageId' ``
            --authentication-type password ``
            --admin-username $adoAgentUser ``
            --admin-password '$adoAgentPass' ``
            --disable-overprovision ``
            --upgrade-policy-mode Manual ``
            --public-ip-address '""' ``
            --tags ServiceName='ADP' ServiceCode='CDO' Name=$vmssName Purpose='ADO Build Agent'
"@
        Invoke-CommandLine -Command $command | Out-Null
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