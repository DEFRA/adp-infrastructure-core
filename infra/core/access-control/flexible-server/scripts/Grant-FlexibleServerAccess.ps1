<#
.SYNOPSIS
Grant access to postgres flexible server for service (tier-3) managed identity.

.DESCRIPTION
Grant access to postgres flexible server for service (tier-3) managed identity.

.EXAMPLE
.\Grant-FlexibleServerAccess.ps1 
#>

Set-StrictMode -Version 3.0

$PostgresHost = $env:POSTGRES_HOST 
$PostgresDatabase = $env:POSTGRES_DATABASE
$ServiceMIName = $env:SERVICE_MI_NAME 
$PlatformMIName = $env:PLATFORM_MI_NAME 
$PlatformMIClientId = $env:AZURE_CLIENT_ID
$PlatformMITenantId = $env:AZURE_TENANT_ID
$PlatformMISubscriptionId = $env:PLATFORM_MI_SUBSCRIPTION_ID 
$PlatformMIFederatedTokenFile = $env:AZURE_FEDERATED_TOKEN_FILE
$SubscriptionName = $env:SUBSCRIPTION_NAME
$WorkingDirectory = $PWD

[string]$functionName = $MyInvocation.MyCommand
[DateTime]$startTime = [DateTime]::UtcNow
[int]$exitCode = -1
[bool]$setHostExitCode = (Test-Path -Path ENV:TF_BUILD) -and ($ENV:TF_BUILD -eq "true")
[bool]$enableDebug = (Test-Path -Path ENV:SYSTEM_DEBUG) -and ($ENV:SYSTEM_DEBUG -eq "true")

Set-Variable -Name ErrorActionPreference -Value Continue -scope global
Set-Variable -Name VerbosePreference -Value Continue -Scope global

if ($enableDebug) {
    Set-Variable -Name DebugPreference -Value Continue -Scope global
    Set-Variable -Name InformationPreference -Value Continue -Scope global
}

Write-Host "${functionName} started at $($startTime.ToString('u'))"
Write-Debug "${functionName}:PostgresHost:$PostgresHost"
Write-Debug "${functionName}:PostgresDatabase:$PostgresDatabase"
Write-Debug "${functionName}:ServiceMIName:$ServiceMIName"
Write-Debug "${functionName}:PlatformMIName:$PlatformMIName"
Write-Debug "${functionName}:PlatformMIClientId=$PlatformMIClientId"
Write-Debug "${functionName}:PlatformMIFederatedTokenFile=$PlatformMIFederatedTokenFile"
Write-Debug "${functionName}:PlatformMITenantId=$PlatformMITenantId"
Write-Debug "${functionName}:PlatformMISubscriptionId=$PlatformMISubscriptionId"
Write-Debug "${functionName}:SubscriptionName=$SubscriptionName"
Write-Debug "${functionName}:WorkingDirectory=$WorkingDirectory"

[System.IO.DirectoryInfo]$scriptDir = $PSCommandPath | Split-Path -Parent
Write-Debug "${functionName}:scriptDir.FullName:$($scriptDir.FullName)"

try {
    [System.IO.DirectoryInfo]$moduleDir = Join-Path -Path $WorkingDirectory -ChildPath "scripts/modules/ps-helpers"
    Write-Debug "${functionName}:moduleDir.FullName=$($moduleDir.FullName)"
    Import-Module $moduleDir.FullName -Force

    Write-Host "Connecting to Azure..."
    $null = Connect-AzAccount -ServicePrincipal -ApplicationId $PlatformMIClientId -FederatedToken $(Get-Content $PlatformMIFederatedTokenFile -raw) -Tenant $PlatformMITenantId -Subscription $PlatformMISubscriptionId
    $null = Set-AzContext -Subscription $SubscriptionName
    Write-Host "Connected to Azure and set context to '$SubscriptionName'"

    Write-Host "Acquiring Access Token..."
    $accessToken = Get-AzAccessToken -ResourceUrl "https://ossrdbms-aad.database.windows.net"
    $ENV:PGPASSWORD = $accessToken.Token
    Write-Host "Access Token Acquired"

    [System.Text.StringBuilder]$builder = [System.Text.StringBuilder]::new()
    [void]$builder.Append(' DO $$ ')
    [void]$builder.Append(' BEGIN ')
    [void]$builder.Append("     IF NOT EXISTS (SELECT 1 FROM pgaadauth_list_principals(false) WHERE rolname='$ServiceMIName') THEN ")
    [void]$builder.Append("         PERFORM pgaadauth_create_principal('$ServiceMIName', false, false); ");
    [void]$builder.Append("         RAISE NOTICE 'MANAGED IDENTITY CREATED';")
    [void]$builder.Append('     ELSE ')
    [void]$builder.Append("         RAISE NOTICE 'MANAGED IDENTITY ALREADY EXISTS';")
    [void]$builder.Append('     END IF; ')
    [void]$builder.Append("     EXECUTE ( 'GRANT CONNECT ON DATABASE `"$PostgresDatabase`" TO `"$ServiceMIName`"' );")
    [void]$builder.Append("     RAISE NOTICE 'GRANTED CONNECT TO DATABASE';")
    [void]$builder.Append(" EXCEPTION ")
    [void]$builder.Append("     WHEN OTHERS THEN  ")
    [void]$builder.Append("         RAISE EXCEPTION 'ERROR DURING PRINCIPAL CREATION/GRANT CONNECT: %', SQLERRM; ")
    [void]$builder.Append(' END $$' )
    [string]$command = $builder.ToString()
    Write-Debug "${functionName}:command=$command"
    
    [System.IO.FileInfo]$tempFile = [System.IO.Path]::GetTempFileName()
    [string]$content = Set-Content -Path $tempFile.FullName -Value $command -PassThru -Force
    Write-Debug "${functionName}:$($tempFile.FullName)=$content"

    [System.Text.StringBuilder]$expressionBuilder = [System.Text.StringBuilder]::new('psql -A -q ')
    [void]$expressionBuilder.Append(" -h " + $PostgresHost)
    [void]$expressionBuilder.Append(" -U " + $PlatformMIName)
    [void]$expressionBuilder.Append(" " + $PostgresDatabase)
    [void]$expressionBuilder.Append(" -f '")
    [void]$expressionBuilder.Append($tempFile.FullName)
    [void]$expressionBuilder.Append("'")

    $expression = $expressionBuilder.ToString()
    Write-Host "Creating Principal in ${PostgresHost} and Granting permissions to ${ServiceMIName}"
    Invoke-CommandLine -Command $expression -NoOutput
    Write-Host "Granted Access to ${PostgresHost}"

    # Successful exit
    $exitCode = 0
} 
catch {
    $exitCode = -2
    Write-Error $_.Exception.ToString()
    throw $_.Exception
}
finally {
    Remove-Item -Path $tempFile.FullName -Force -ErrorAction SilentlyContinue

    [DateTime]$endTime = [DateTime]::UtcNow
    [Timespan]$duration = $endTime.Subtract($startTime)

    Write-Host "${functionName} finished at $($endTime.ToString('u')) (duration $($duration -f 'g')) with exit code $exitCode"

    if ($setHostExitCode) {
        Write-Debug "${functionName}:Setting host exit code"
        $host.SetShouldExit($exitCode)
    }
    exit $exitCode
}