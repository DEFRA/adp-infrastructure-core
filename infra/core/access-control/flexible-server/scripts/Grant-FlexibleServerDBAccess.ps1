<#
.SYNOPSIS
Grant access to postgres flexible server database for service (tier-3) managed identity.

.DESCRIPTION
Grant access to postgres flexible server database for service (tier-3) managed identity.

.EXAMPLE
.\Grant-FlexibleServerDBAccess.ps1 
#>

Set-StrictMode -Version 3.0

[string]$PostgresHost = $env:POSTGRES_HOST
[string]$PostgresDatabase = $env:POSTGRES_DATABASE
[string]$ServiceMIName = $env:SERVICE_MI_NAME
[string]$TeamMIName = $env:TEAM_MI_NAME
[string]$TeamMIClientId = $env:AZURE_CLIENT_ID
[string]$TeamMITenantId = $env:AZURE_TENANT_ID
[string]$TeamMISubscriptionId = $env:TEAM_MI_SUBSCRIPTION_ID
[string]$TeamMIFederatedTokenFile = $env:AZURE_FEDERATED_TOKEN_FILE
[string]$SubscriptionName = $env:SUBSCRIPTION_NAME
[string]$WorkingDirectory = $PWD

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
Write-Debug "${functionName}:TeamMIName:$TeamMIName"
Write-Debug "${functionName}:TeamMIClientId=$TeamMIClientId"
Write-Debug "${functionName}:TeamMIFederatedTokenFile=$TeamMIFederatedTokenFile"
Write-Debug "${functionName}:TeamMITenantId=$TeamMITenantId"
Write-Debug "${functionName}:TeamMISubscriptionId=$TeamMISubscriptionId"
Write-Debug "${functionName}:SubscriptionName=$SubscriptionName"
Write-Debug "${functionName}:WorkingDirectory=$WorkingDirectory"

[System.IO.DirectoryInfo]$scriptDir = $PSCommandPath | Split-Path -Parent
Write-Debug "${functionName}:scriptDir.FullName:$($scriptDir.FullName)"

try {
    [System.IO.DirectoryInfo]$moduleDir = Join-Path -Path $WorkingDirectory -ChildPath "scripts/modules/ps-helpers"
    Write-Debug "${functionName}:moduleDir.FullName=$($moduleDir.FullName)"
    Import-Module $moduleDir.FullName -Force

    Write-Host "Connecting to Azure..."
    $null = Connect-AzAccount -ServicePrincipal -ApplicationId $TeamMIClientId -FederatedToken $(Get-Content $TeamMIFederatedTokenFile -raw) -Tenant $TeamMITenantId -Subscription $TeamMISubscriptionId
    $null = Set-AzContext -Subscription $SubscriptionName
    Write-Host "Connected to Azure and set context to '$SubscriptionName'"

    Write-Host "Acquiring Access Token..."
    $accessToken = Get-AzAccessToken -ResourceUrl "https://ossrdbms-aad.database.windows.net"
    $ENV:PGPASSWORD = $accessToken.Token
    Write-Debug "${functionName}:accessToken:$ENV:PGPASSWORD"
    Write-Host "Access Token Acquired"

    [System.Text.StringBuilder]$builder = [System.Text.StringBuilder]::new()
    [void]$builder.Append("GRANT CREATE, USAGE ON SCHEMA public TO `"$ServiceMIName`";")
    [void]$builder.Append("GRANT SELECT, UPDATE, INSERT, REFERENCES, TRIGGER ON ALL TABLES IN SCHEMA public TO `"$ServiceMIName`";")
    [void]$builder.Append("GRANT SELECT, UPDATE, USAGE ON ALL SEQUENCES IN SCHEMA public TO `"$ServiceMIName`";")
    [void]$builder.Append("GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO `"$ServiceMIName`";")
    [void]$builder.Append("GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA public TO `"$ServiceMIName`";")
    
    [string]$command = $builder.ToString()
    Write-Debug "${functionName}:command=$command"
    
    [System.IO.FileInfo]$tempFile = [System.IO.Path]::GetTempFileName()
    [string]$content = Set-Content -Path $tempFile.FullName -Value $command -PassThru -Force
    Write-Debug "${functionName}:$($tempFile.FullName)=$content"

    [System.Text.StringBuilder]$expressionBuilder = [System.Text.StringBuilder]::new('psql -A -q ')
    [void]$expressionBuilder.Append(" -h " + $PostgresHost)
    [void]$expressionBuilder.Append(" -U " + $TeamMIName)
    [void]$expressionBuilder.Append(" " + $PostgresDatabase)
    [void]$expressionBuilder.Append(" -f '")
    [void]$expressionBuilder.Append($tempFile.FullName)
    [void]$expressionBuilder.Append("'")

    $expression = $expressionBuilder.ToString()
    Write-Host "Granting permissions to ${ServiceMIName}"
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