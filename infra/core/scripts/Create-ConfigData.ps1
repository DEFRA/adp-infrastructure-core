[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $ServicePrincipalId,
    [Parameter(Mandatory)]
    [string] $ServicePrincipalKey,
    [Parameter(Mandatory)]
    [string] $AzureSubscription,
    [Parameter(Mandatory)]
    [string] $TenantId,
    [Parameter(Mandatory)]
    [string] $AppConfigName,
    [Parameter(Mandatory)]
    [string] $ConfigDataFilePath,
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
Write-Debug "${functionName}:ServicePrincipalId=$ServicePrincipalId"
Write-Debug "${functionName}:AzureSubscription=$AzureSubscription"
Write-Debug "${functionName}:TenantId=$TenantId"
Write-Debug "${functionName}:AppConfigName=$AppConfigName"
Write-Debug "${functionName}:ConfigDataFilePath=$ConfigDataFilePath"
Write-Debug "${functionName}:WorkingDirectory=$WorkingDirectory"

try {

    Install-Module -Name "Az.Accounts" -RequiredVersion "2.2.3" -Force -SkipPublisherCheck -AllowClobber
    # Install-Module -Name "Az.KeyVault" -RequiredVersion "4.10.2" -Force -SkipPublisherCheck -AllowClobber

    [System.IO.DirectoryInfo]$moduleDir = Join-Path -Path $WorkingDirectory -ChildPath "scripts/modules/ps-helpers"
    Write-Debug "${functionName}:moduleDir.FullName=$($moduleDir.FullName)"
    Import-Module $moduleDir.FullName -Force

    Write-Host "${functionName}:Connecting to Azure..."
    [SecureString]$SecuredPassword = ConvertTo-SecureString -AsPlainText -String $ServicePrincipalKey
    [PSCredential]$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ServicePrincipalId, $SecuredPassword
    $null = Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Credential $Credential
    $null = Set-AzContext -Subscription $AzureSubscription
    Write-Host "${functionName}:Connected to Azure and set context to '$AzureSubscription'"
    
    # Get-Image -KeyVaultName $KeyVaultName -NGINXCertSecretName $NGINXCertSecretName -NGINXKeySecretName $NGINXKeySecretName -NGINXVersion $NGINXVersion

    # Publish-Image -AcrName $AcrName.ToLower() -NGINXVersion $NGINXVersion

    $settings = Get-Content -Path $(Join-Path -Path $WorkingDirectory -ChildPath $ConfigDataFilePath)

    $settings | ConvertFrom-Json | ForEach-Object {
        az appconfig kv set `
            --name $AppConfigName `
            --key $_.key `
            --value $_.value `
            --content-type $_.contentType `
            --label $_.label
        # --yes | Out-Null
    }

    # az appconfig kv set --name $appConfigName --key $newKey --value "Value 1"

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
