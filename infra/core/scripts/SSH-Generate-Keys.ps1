[CmdletBinding()]
param(
[Parameter(Mandatory)]
[string] $AzureSubscription,
[Parameter(Mandatory)]
[string] $KeyVaultName,
[Parameter(Mandatory)]
[string] $KeyVaultRgName,
[Parameter(Mandatory)]
[string] $KeyVaultSubscriptionId,
[Parameter(Mandatory)]
[string] $SSHPrivateKeySecretName,
[Parameter(Mandatory)]
[string] $SSHPublicKeySecretName,
[Parameter(Mandatory)]
[string]$KnownHostsSecretName,
[Parameter(Mandatory)]
[ValidateSet("ecdsa-sha2-nistp384")]
[string]$SSHKeyType,
[Parameter(Mandatory)]
[string]$AppConfigMIRgName,
[Parameter(Mandatory)]
[string]$AppConfigMIName,
[Parameter()]
[string]$WorkingDirectory = $PWD
)

function Set-KeyVaultSecret {
    param(
        [Parameter(Mandatory)]
        [string]$KeyVaultName,
        [Parameter(Mandatory)]
        [string]$SecretName,
        [Parameter]
        [string]$File,
        [Parameter]
        [string]$Value,
        [Parameter()]
        [string]$Encoding = "utf-8"
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand
        Write-Debug "${functionName}:Entered"
        Write-Debug "${functionName}:KeyVaultName=$KeyVaultName"
        Write-Debug "${functionName}:SecretName=$SecretName"
        Write-Debug "${functionName}:File=$File"
        Write-Debug "${functionName}:Encoding=$Encoding"
    }

    process {
        Write-Host "Uploading Secrect to KeyVault. Secrect name: $SecretName"
        if ($File) {
            $command = "az keyvault secret set --vault-name $KeyVaultName --name $SecretName --file $File --encoding $Encoding"
        } else {
            $command = "az keyvault secret set --vault-name $KeyVaultName --name $SecretName --value $Value --encoding $Encoding"
        }
        Invoke-CommandLine -Command $command -NoOutput
        Write-Host "Uploaded Secrect to KeyVault"
    }
    
    end {
        Write-Debug "${functionName}:Exited"
    }
}

function Set-SecretsUserRoleAssignment {
    param(
        [Parameter(Mandatory)]
        [string]$SubscriptionId,
        [Parameter(Mandatory)]
        [string]$PrincipalId,
        [Parameter(Mandatory)]
        [string]$KeyVaultName,
        [Parameter(Mandatory)]
        [string]$KeyVaultRgName,
        [Parameter(Mandatory)]
        [string]$SecretName
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand
        Write-Debug "${functionName}:Entered"
        Write-Debug "${functionName}:SubscriptionId=$SubscriptionId"
        Write-Debug "${functionName}:PrincipalId=$PrincipalId"
        Write-Debug "${functionName}:KeyVaultName=$KeyVaultName"
        Write-Debug "${functionName}:KeyVaultRgName=$KeyVaultRgName"
        Write-Debug "${functionName}:SecretName=$SecretName"
    }
    process {
        
        $keyVaultSecretsUserRole = "Key Vault Secrets User"
        Write-Host "Assigning $keyVaultSecretsUserRole role to $PrincipalId on $SecretName"
        [string]$scopeIdPrivateKeySecret = "/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.KeyVault/vaults/{2}/secrets/{3}" -f $SubscriptionId, $KeyVaultRgName, $KeyVaultName, $SecretName
        Write-Debug "${functionName}:scopeIdPrivateKeySecret=$scopeIdPrivateKeySecret"
        Invoke-CommandLine -Command "az role assignment create --assignee $PrincipalId --role '$keyVaultSecretsUserRole' --scope $scopeIdPrivateKeySecret" -NoOutput
        Write-Host "Assigned $keyVaultSecretsUserRole role to $PrincipalId on $SecretName"
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
Write-Debug "${functionName}:AzureSubscription=$AzureSubscription"
Write-Debug "${functionName}:KeyVaultName=$KeyVaultName"
Write-Debug "${functionName}:KeyVaultRgName=$KeyVaultRgName"
Write-Debug "${functionName}:KeyVaultSubscriptionId=$KeyVaultSubscriptionId"
Write-Debug "${functionName}:SSHPrivateKeySecretName=$SSHPrivateKeySecretName"
Write-Debug "${functionName}:SSHPublicKeySecretName=$SSHPublicKeySecretName"
Write-Debug "${functionName}:KnownHostsSecretName=$KnownHostsSecretName"
Write-Debug "${functionName}:SSHKeyType=$SSHKeyType"
Write-Debug "${functionName}:AppConfigMIRgName=$AppConfigMIRgName"
Write-Debug "${functionName}:AppConfigMIName=$AppConfigMIName"
Write-Debug "${functionName}:WorkingDirectory=$WorkingDirectory"

try {

    [System.IO.DirectoryInfo]$moduleDir = Join-Path -Path $WorkingDirectory -ChildPath "scripts/modules/ps-helpers"
    Write-Debug "${functionName}:moduleDir.FullName=$($moduleDir.FullName)"
    Import-Module $moduleDir.FullName -Force
    Install-Module -Name Az.ManagedServiceIdentity -Force

    Write-Host "Connecting to Azure..."
    [SecureString]$SecuredPassword = ConvertTo-SecureString -AsPlainText -String $env:servicePrincipalKey
    [PSCredential]$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $env:servicePrincipalId, $SecuredPassword
    $null = Connect-AzAccount -ServicePrincipal -TenantId $env:tenantId -Credential $Credential
    $null = Set-AzContext -Subscription $AzureSubscription
    Write-Host "Connected to Azure and set context to '$AzureSubscription'"

    Write-Host "Getting App Config Managed Identity PrincipalId"
    $appConfigMiPrincipalId = (Get-AzUserAssignedIdentity -ResourceGroupName $AppConfigMIRgName -Name $AppConfigMIName).PrincipalId 
    Write-Debug "${functionName}:appConfigMiPrincipalId=$appConfigMiPrincipalId"

    Write-Host "Generating SSH keys for key type: ${SSHKeyType}"
    Invoke-CommandLine -Command "ssh-keygen -t $SSHKeyType -f id_ecdsa -N '""""' -C '""""'" -NoOutput
    Write-Host "Generated SSH keys"

    Set-KeyVaultSecret -KeyVaultName $KeyVaultName -SecretName $SSHPrivateKeySecretName -File "id_ecdsa"
    Set-KeyVaultSecret -KeyVaultName $KeyVaultName -SecretName $SSHPublicKeySecretName -File "id_ecdsa.pub"

    Write-Host "Getting known_hosts for github.com"
    $knownHosts = Invoke-CommandLine -Command "ssh-keyscan -t $SSHKeyType github.com"
    Write-Host "Got known_hosts for github.com"

    Set-KeyVaultSecret -KeyVaultName $KeyVaultName -SecretName $KnownHostsSecretName -Value $knownHosts

    Set-SecretsUserRoleAssignment -SubscriptionId $KeyVaultSubscriptionId -PrincipalId $appConfigMiPrincipalId -KeyVaultName $KeyVaultName -KeyVaultRgName $KeyVaultRgName -SecretName $SSHPrivateKeySecretName 
    Set-SecretsUserRoleAssignment -SubscriptionId $KeyVaultSubscriptionId -PrincipalId $appConfigMiPrincipalId -KeyVaultName $KeyVaultName -KeyVaultRgName $KeyVaultRgName -SecretName $SSHPublicKeySecretName
    Set-SecretsUserRoleAssignment -SubscriptionId $KeyVaultSubscriptionId -PrincipalId $appConfigMiPrincipalId -KeyVaultName $KeyVaultName -KeyVaultRgName $KeyVaultRgName -SecretName $KnownHostsSecretName

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