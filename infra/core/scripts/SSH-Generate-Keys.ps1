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

try {

    [System.IO.DirectoryInfo]$moduleDir = Join-Path -Path $WorkingDirectory -ChildPath "scripts/modules/ps-helpers"
    Write-Debug "${functionName}:moduleDir.FullName=$($moduleDir.FullName)"
    Import-Module $moduleDir.FullName -Force

    Write-Host "Connecting to Azure..."
    Invoke-CommandLine -Command "az login --service-principal --tenant $TenantId --username $ServicePrincipalId --password $ServicePrincipalKey" -NoOutput
    Invoke-CommandLine -Command "az account set --name $AzureSubscription" -NoOutput
    Write-Host "Connected to Azure and set context to '$AzureSubscription'"

    Invoke-CommandLine -Command "ssh-keygen -t ecdsa-sha2-nistp384 -f id_ecdsa -P '' -C ''" -NoOutput

    Invoke-CommandLine -Command "az keyvault secret set --vault-name $KeyVaultName --name $SSHPrivateKeySecretName --file id_ecdsa --encoding utf-8" -NoOutput

    Invoke-CommandLine -Command "az keyvault secret set --vault-name $KeyVaultName --name $SSHPublicKeySecretName --file id_ecdsa.pub --encoding utf-8" -NoOutput

    $knownHosts = Invoke-CommandLine -Command "ssh-keyscan -t ecdsa-sha2-nistp384 -H github.com"

    Invoke-CommandLine -Command "az keyvault secret set --vault-name $KeyVaultName --name $KnownHostsSecretName --value $knownHosts --encoding utf-8" -NoOutput

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