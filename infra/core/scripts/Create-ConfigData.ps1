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
    [Parameter()]
    [object] $ConfigData,
    [Parameter()]
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
Write-Debug "${functionName}:ConfigData=$ConfigData"
Write-Debug "${functionName}:ConfigDataFilePath=$ConfigDataFilePath"
Write-Debug "${functionName}:WorkingDirectory=$WorkingDirectory"

try {
    if ($null -eq $ConfigData -and $null -eq $ConfigDataFilePath) {
        throw "One of the parameters 'ConfigData' or 'ConfigDataFilePath' is required."
    }

    [System.IO.DirectoryInfo]$moduleDir = Join-Path -Path $WorkingDirectory -ChildPath "scripts/modules/ps-helpers"
    Write-Debug "${functionName}:moduleDir.FullName=$($moduleDir.FullName)"
    Import-Module $moduleDir.FullName -Force

    Write-Host "${functionName}:Connecting to Azure..."
    Invoke-CommandLine -Command "az login --service-principal --tenant $TenantId --username $ServicePrincipalId --password $ServicePrincipalKey" -NoOutput
    Invoke-CommandLine -Command "az account set --name $AzureSubscription" -NoOutput
    Write-Host "${functionName}:Connected to Azure and set context to '$AzureSubscription'"
    
    Invoke-CommandLine -Command "az appconfig update --name $AppConfigName --disable-local-auth $false" -NoOutput
    
    if ($ConfigData) {
        $settings = $Configdata.configuration
    }
    if ($ConfigDataFilePath) {
        $settings = Get-Content -Path $(Join-Path -Path $WorkingDirectory -ChildPath $ConfigDataFilePath)
    }

    $settings | ConvertFrom-Json | ForEach-Object {
        Write-Host "Adding key '$($_.name)' with label '$($_.label)' to the config store"
        Invoke-CommandLine -Command "az appconfig kv set --name $AppConfigName --key $($_.name) --value $($_.value) --label $($_.label) --yes" -NoOutput
    }

    Invoke-CommandLine -Command "az appconfig update --name $AppConfigName --disable-local-auth $true" -NoOutput

    Invoke-CommandLine -Command "az logout" -NoOutput

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
