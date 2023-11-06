[CmdletBinding()]
param(
[Parameter(Mandatory)]
[string] $TenantId,    
[Parameter(Mandatory)]
[string] $ServicePrincipalId,
[Parameter(Mandatory)]
[string] $ServicePrincipalKey,
[Parameter(Mandatory)]
[string] $AzureSubscription,
[Parameter(Mandatory)]
[string] $KeyVaultName,
[Parameter(Mandatory)]
[string] $SSHPrivateKeySecretName,
[Parameter(Mandatory)]
[string] $SSHPublicKeySecretName,
[Parameter(Mandatory)]
[string]$KnownHostsSecretName,
[Parameter(Mandatory)]
[ValidateSet("ecdsa-sha2-nistp384")]
[string]$SSHKeyType,
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
Write-Debug "${functionName}:TenantId=$TenantId"
Write-Debug "${functionName}:ServicePrincipalId=$ServicePrincipalId"
Write-Debug "${functionName}:AzureSubscription=$AzureSubscription"
Write-Debug "${functionName}:KeyVaultName=$KeyVaultName"
Write-Debug "${functionName}:SSHPrivateKeySecretName=$SSHPrivateKeySecretName"
Write-Debug "${functionName}:SSHPublicKeySecretName=$SSHPublicKeySecretName"
Write-Debug "${functionName}:KnownHostsSecretName=$KnownHostsSecretName"
Write-Debug "${functionName}:SSHKeyType=$SSHKeyType"
Write-Debug "${functionName}:WorkingDirectory=$WorkingDirectory"

try {

    [System.IO.DirectoryInfo]$moduleDir = Join-Path -Path $WorkingDirectory -ChildPath "scripts/modules/ps-helpers"
    Write-Debug "${functionName}:moduleDir.FullName=$($moduleDir.FullName)"
    Import-Module $moduleDir.FullName -Force

    Write-Host "Connecting to Azure..."
    Invoke-CommandLine -Command "az login --service-principal --tenant $TenantId --username $ServicePrincipalId --password $ServicePrincipalKey" -NoOutput
    Invoke-CommandLine -Command "az account set --name $AzureSubscription" -NoOutput
    Write-Host "Connected to Azure and set context to '$AzureSubscription'"


    Write-Host "Generating SSH keys for key type: ${SSHKeyType}"
    Invoke-CommandLine -Command "ssh-keygen -t $SSHKeyType -f id_ecdsa -P '' -C ''" -NoOutput
    Write-Host "Generated SSH keys"

    Write-Host "Uploading SSH Private key to KeyVault. SSHPrivateKeySecretName: $SSHPrivateKeySecretName"
    Invoke-CommandLine -Command "az keyvault secret set --vault-name $KeyVaultName --name $SSHPrivateKeySecretName --file id_ecdsa --encoding utf-8" -NoOutput
    Write-Host "Uploaded SSH Private key to KeyVault"

    Write-Host "Uploading SSH Public key to KeyVault. SSHPublicKeySecretName: $SSHPublicKeySecretName"
    Invoke-CommandLine -Command "az keyvault secret set --vault-name $KeyVaultName --name $SSHPublicKeySecretName --file id_ecdsa.pub --encoding utf-8" -NoOutput
    Write-Host "Uploaded SSH Public key to KeyVault"

    $knownHosts = Invoke-CommandLine -Command "ssh-keyscan -t $SSHKeyType -H github.com"

    Write-Host "Uploading known_hosts to KeyVault. KnownHostsSecretName: $KnownHostsSecretName"
    Invoke-CommandLine -Command "az keyvault secret set --vault-name $KeyVaultName --name $KnownHostsSecretName --value '$knownHosts' --encoding utf-8" -NoOutput
    Write-Host "Uploaded known_hosts to KeyVault"

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