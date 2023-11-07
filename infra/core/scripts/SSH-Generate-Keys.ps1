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

    $keyVaultSecretsUserRole = "Key Vault Secrets User"

    Write-Host "Getting App Config Managed Identity PrincipalId"
    $appConfigMiPrincipalId = (Get-AzUserAssignedIdentity -ResourceGroupName $AppConfigMIRgName -Name $AppConfigMIName).PrincipalId 
    Write-Debug "${functionName}:appConfigMiPrincipalId=$appConfigMiPrincipalId"

    Write-Host "Generating SSH keys for key type: ${SSHKeyType}"
    Invoke-CommandLine -Command "ssh-keygen -t $SSHKeyType -f id_ecdsa -N '""""' -C '""""'" -NoOutput
    Write-Host "Generated SSH keys"

    Write-Host "Uploading SSH Private key to KeyVault. SSHPrivateKeySecretName: $SSHPrivateKeySecretName"
    Invoke-CommandLine -Command "az keyvault secret set --vault-name $KeyVaultName --name $SSHPrivateKeySecretName --file id_ecdsa --encoding utf-8" -NoOutput
    Write-Host "Uploaded SSH Private key to KeyVault"

    Write-Host "Assigning $keyVaultSecretsUserRole role to $appConfigMiPrincipalId on $SSHPrivateKeySecretName"
    [string]$scopeIdPrivateKeySecret = "/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.KeyVault/vaults/{2}/secrets/{3}" -f $KeyVaultSubscriptionId, $KeyVaultRgName, $KeyVaultName, $SSHPrivateKeySecretName
    Invoke-CommandLine -Command "az role assignment create --assignee $appConfigMiPrincipalId --role '$keyVaultSecretsUserRole' --scope $scopeIdPrivateKeySecret" -NoOutput
    Write-Host "Assigned $keyVaultSecretsUserRole role to $appConfigMiPrincipalId on $SSHPrivateKeySecretName"

    Write-Host "Uploading SSH Public key to KeyVault. SSHPublicKeySecretName: $SSHPublicKeySecretName"
    Invoke-CommandLine -Command "az keyvault secret set --vault-name $KeyVaultName --name $SSHPublicKeySecretName --file id_ecdsa.pub --encoding utf-8" -NoOutput
    Write-Host "Uploaded SSH Public key to KeyVault"

    Write-Host "Assigning $keyVaultSecretsUserRole role to $appConfigMiPrincipalId on $SSHPublicKeySecretName"
    [string]$scopeIdPrivateKeySecret = "/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.KeyVault/vaults/{2}/secrets/{3}" -f $KeyVaultSubscriptionId, $KeyVaultRgName, $KeyVaultName, $SSHPublicKeySecretName
    Invoke-CommandLine -Command "az role assignment create --assignee $appConfigMiPrincipalId --role '$keyVaultSecretsUserRole' --scope $scopeIdPrivateKeySecret" -NoOutput
    Write-Host "Assigned $keyVaultSecretsUserRole role to $appConfigMiPrincipalId on $SSHPublicKeySecretName"

    Write-Host "Getting known_hosts for github.com"
    $knownHosts = Invoke-CommandLine -Command "ssh-keyscan -t $SSHKeyType github.com"
    Write-Host "Got known_hosts for github.com"

    Write-Host "Uploading known_hosts to KeyVault. KnownHostsSecretName: $KnownHostsSecretName"
    Invoke-CommandLine -Command "az keyvault secret set --vault-name $KeyVaultName --name $KnownHostsSecretName --value '$knownHosts' --encoding utf-8" -NoOutput
    Write-Host "Uploaded known_hosts to KeyVault"

    Write-Host "Assigning $keyVaultSecretsUserRole role to $appConfigMiPrincipalId on $KnownHostsSecretName"
    [string]$scopeIdPrivateKeySecret = "/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.KeyVault/vaults/{2}/secrets/{3}" -f $KeyVaultSubscriptionId, $KeyVaultRgName, $KeyVaultName, $KnownHostsSecretName
    Invoke-CommandLine -Command "az role assignment create --assignee $appConfigMiPrincipalId --role '$keyVaultSecretsUserRole' --scope $scopeIdPrivateKeySecret" -NoOutput
    Write-Host "Assigned $keyVaultSecretsUserRole role to $appConfigMiPrincipalId on $KnownHostsSecretName"

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