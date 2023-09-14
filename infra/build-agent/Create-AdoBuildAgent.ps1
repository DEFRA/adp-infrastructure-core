<#
.SYNOPSIS
Create Virtual Machine Scale-set
.DESCRIPTION
Create Virtual Machine Scale-set for private build agent using image from the shared compute gallery.
.PARAMETER ImageGalleryTenantId
Mandatory. Image Gallery Tenant Id.
.PARAMETER TenantId
Mandatory. Tenant Id.
.PARAMETER SubscriptionName
Mandatory. Subscription Name.
.PARAMETER ResourceGroup
Mandatory. Resource Group Name.
.PARAMETER VMSSName
Mandatory. Virtual Machine Scale-Set name.
.PARAMETER SubnetId
Mandatory. Subnet ResourceId.
.PARAMETER ImageId
Mandatory. Shared Gallery Image Reference Id.
.PARAMETER AdoAgentUser
Mandatory. VM instance login user name.
.PARAMETER AdoAgentPass
Mandatory. VM instance login password.
.EXAMPLE
.\Create-AdoBuildAgent.ps1  -imageGalleryTenantId <ImageGalleryTenantId> -tenantId <TenantId> -subscriptionName <SubscriptionName> -resourceGroup <ResourceGroup> `
                            -vmssName <VMSSName> -subnetId <SubnetId> -imageId <ImageId> -adoAgentUser <AdoAgentUser> -adoAgentPass <AdoAgentPass>
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $ImageGalleryTenantId,
    [Parameter(Mandatory)]
    [string] $TenantId,
    [Parameter(Mandatory)]
    [string] $SubscriptionName,
    [Parameter(Mandatory)]
    [string] $ResourceGroup,
    [Parameter(Mandatory)]
    [string] $VMSSName,
    [Parameter(Mandatory)]
    [string] $SubnetId,
    [Parameter(Mandatory)]
    [string] $ImageId,
    [Parameter(Mandatory)]
    [string] $AdoAgentUser,
    [Parameter(Mandatory)]
    [string] $AdoAgentPass,
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
Write-Debug "${functionName}:ImageGalleryTenantId=$ImageGalleryTenantId"
Write-Debug "${functionName}:TenantId=$TenantId"
Write-Debug "${functionName}:SubscriptionName=$SubscriptionName"
Write-Debug "${functionName}:ResourceGroup=$ResourceGroup"
Write-Debug "${functionName}:VMSSName=$VMSSName"
Write-Debug "${functionName}:SubnetId=$SubnetId"
Write-Debug "${functionName}:ImageId=$ImageId"
Write-Debug "${functionName}:WorkingDirectory=$WorkingDirectory"


try {

    [System.IO.DirectoryInfo]$moduleDir = Join-Path -Path $WorkingDirectory -ChildPath "scripts/modules/ps-helpers"
    Write-Debug "${functionName}:moduleDir.FullName=$($moduleDir.FullName)"
    Import-Module $moduleDir.FullName -Force

    [string]$command = "az account clear"
    Invoke-CommandLine -Command $command | Out-Null
    
    if ($ImageGalleryTenantId -ne $TenantId) {
        $command = "az login --service-principal -u $($env:servicePrincipalId) -p $($env:servicePrincipalKey) --tenant $ImageGalleryTenantId"
        Invoke-CommandLine -Command $command | Out-Null
        $command = "az account get-access-token"
        Invoke-CommandLine -Command $command | Out-Null
    }

    $command = "az login --service-principal -u $($env:servicePrincipalId) -p $($env:servicePrincipalKey) --tenant $TenantId"
    Invoke-CommandLine -Command $command | Out-Null
    $command = "az account get-access-token"
    Invoke-CommandLine -Command $command | Out-Null

    $command = "az account set --subscription $SubscriptionName"
    Invoke-CommandLine -Command $command | Out-Null

    Write-Host "Checking if the VMSS $VMSSName already exists..."
    $command = "az vmss list --resource-group $ResourceGroup"
    [string]$commandOutput = Invoke-CommandLine -Command $command

    $instances = $commandOutput | ConvertFrom-Json
    if ($instances -and $instances.count -gt 0 -and ($instances.name -contains $VMSSName)) {
        Write-Host "VMSS: $VMSSName already exists!"
    }
    else {
        Write-Host "Creating VMSS: $VMSSName..."
        
        $command = @"
            az vmss create ``
            --resource-group $ResourceGroup ``
            --name $VMSSName ``
            --computer-name-prefix $VMSSName ``
            --vm-sku Standard_D4s_v4 ``
            --instance-count 2 ``
            --subnet '$SubnetId' ``
            --image '$ImageId' ``
            --authentication-type password ``
            --admin-username $AdoAgentUser ``
            --admin-password '$AdoAgentPass' ``
            --disable-overprovision ``
            --upgrade-policy-mode Manual ``
            --public-ip-address '""' ``
            --load-balancer '""' ``
            --tags ServiceName='ADP' ServiceCode='CDO' Name=$VMSSName Purpose='ADO Build Agent'
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