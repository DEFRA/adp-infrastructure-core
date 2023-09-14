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
.PARAMETER Location
Mandatory. Location.
.PARAMETER KeyVaultName
Mandatory. Key Vault Name.
.PARAMETER SecretsPrefix
Mandatory. Secrets Prefix.
.EXAMPLE
.\Create-AdoBuildAgent.ps1  -ImageGalleryTenantId <ImageGalleryTenantId> -TenantId <TenantId> -SubscriptionName <SubscriptionName> -ResourceGroup <ResourceGroup> `
                            -VMSSName <VMSSName> -SubnetId <SubnetId> -ImageId <ImageId> -Location <Location> -KeyVaultName <KeyVaultName> -SecretsPrefix <SecretsPrefix>
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
    [string] $Location,
    [Parameter(Mandatory)]
    [string] $KeyVaultName,
    [Parameter(Mandatory)]
    [string] $SecretsPrefix,
    [Parameter()]
    [string]$WorkingDirectory = $PWD
)

function New-AdminUsernameRandom {
    [CmdletBinding()]
    param ()

    begin {
        [string]$functionName = $MyInvocation.MyCommand
        Write-Debug "${functionName}:Entered"
    }

    process {
        [string]$lowerCase = "abcdefghijklmnopqrstuvwxyz"
        [string]$adminUsername = ""
        for ($i = 0; $i -lt 9; $i++) {
            $adminUsername += Get-Random -Count 1 -InputObject $lowerCase.ToCharArray()
        }

        $adminUsername+= $(Get-Random -Minimum 1000 -Maximum 9999)
        return $adminUsername
    }

    end {
        Write-Debug "${functionName}:Exited"
    }
}

function New-PasswordRandom {
    [CmdletBinding()]
    param (
        [int]$Length = 12
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand
        Write-Debug "${functionName}:Entered"
        Write-Debug "${functionName}:Length=$Length"
    }

    process {

        [string]$validChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-="
        [string]$lowerCase = "abcdefghijklmnopqrstuvwxyz"
        [string]$upperCase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        [string]$numbers = "0123456789"
        [string]$specialChars = "!@#$%^&*()_+-="
    
        if ($length -lt 12) {
            $length = 12
        } elseif ($length -gt 72) {
            $length = 72
        }
    
        [string]$password = ""
        $password += Get-Random -Count 1 -InputObject $lowerCase.ToCharArray()
        $password += Get-Random -Count 1 -InputObject $upperCase.ToCharArray()
        $password += Get-Random -Count 1 -InputObject $numbers.ToCharArray()
        $password += Get-Random -Count 1 -InputObject $specialChars.ToCharArray()
    
        for ($i = 0; $i -lt ($length - 4); $i++) {
            $password += Get-Random -Count 1 -InputObject $validChars.ToCharArray()
        }
    
        $password = -join ($password.ToCharArray() | Get-Random -Count $length)
        return $password
    }

    end {
        Write-Debug "${functionName}:Exited"
    }
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
Write-Debug "${functionName}:ImageGalleryTenantId=$ImageGalleryTenantId"
Write-Debug "${functionName}:TenantId=$TenantId"
Write-Debug "${functionName}:SubscriptionName=$SubscriptionName"
Write-Debug "${functionName}:ResourceGroup=$ResourceGroup"
Write-Debug "${functionName}:VMSSName=$VMSSName"
Write-Debug "${functionName}:SubnetId=$SubnetId"
Write-Debug "${functionName}:ImageId=$ImageId"
Write-Debug "${functionName}:Location=$Location"
Write-Debug "${functionName}:KeyVaultName=$KeyVaultName"
Write-Debug "${functionName}:WorkingDirectory=$WorkingDirectory"

try {

    [System.IO.DirectoryInfo]$moduleDir = Join-Path -Path $WorkingDirectory -ChildPath "scripts/modules/ps-helpers"
    Write-Debug "${functionName}:moduleDir.FullName=$($moduleDir.FullName)"
    Import-Module $moduleDir.FullName -Force

    if (!(Invoke-CommandLine -Command "az group show --name $ResourceGroup --output none --query id" -IgnoreErrorCode)) {
        Invoke-CommandLine "az group create --name $ResourceGroup --location $location" | Out-Null
        Write-Host "Resource Group '$ResourceGroup' created successfully."
    }
    else {
        Write-Host "Resource Group '$ResourceGroup' already exists."
    }

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
        
        [string]$adminUsername = New-AdminUsernameRandom
        [securestring]$adminPassword = ConvertTo-SecureString -String (New-PasswordRandom -Length 12) -AsPlainText -Force
        [string]$command = @"
            az vmss create ``
            --resource-group $ResourceGroup ``
            --name $VMSSName ``
            --computer-name-prefix $VMSSName ``
            --vm-sku Standard_D4s_v4 ``
            --instance-count 2 ``
            --subnet '$SubnetId' ``
            --image '$ImageId' ``
            --authentication-type password ``
            --admin-username $adminUsername ``
            --admin-password '$adminPassword' ``
            --disable-overprovision ``
            --upgrade-policy-mode Manual ``
            --public-ip-address '""' ``
            --load-balancer '""' ``
            --tags ServiceName='ADP' ServiceCode='ADP' Name=$VMSSName Purpose='ADO Build Agent'
"@
        Invoke-CommandLine -Command $command -IsSensitive | Out-Null

        [string]$adminUsernamekvSecretName =  "{0}-ADO-BuildAgent-User" -f $SecretsPrefix
        Write-Debug "${functionName}:adminUsernamekvSecretName=$adminUsernamekvSecretName"

        [string]$adminPwdkvSecretName = "{0}-ADO-BuildAgent-Password" -f $SecretsPrefix
        Write-Debug "${functionName}:adminPwdkvSecretName=$adminPwdkvSecretName"

        Invoke-CommandLine -Command "az keyvault secret set --name $adminUsernamekvSecretName --vault-name $KeyVaultName --content-type 'User Name' --value $adminUsername" | Out-Null

        Invoke-CommandLine "az keyvault secret set --name $adminPwdkvSecretName --vault-name $KeyVaultName --content-type 'Password' --value $adminPassword" | Out-Null
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