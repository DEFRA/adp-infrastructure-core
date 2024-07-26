<#
.SYNOPSIS
Create or Update an Azure RM type service endpoint (ServiceConnection).

.DESCRIPTION
Create an Azure RM type service endpoint (ServiceConnection). It also verifies the service endpoint using endpointproxy.

.PARAMETER ServiceEndpointJsonPath
Mandatory. Service connection configuration file.

.PARAMETER WorkingDirectory
Optional. Working directory. Default is $PWD.

.EXAMPLE
.\Initialize-ServiceEndpoint.ps1 -ServiceEndpointJsonPath <Service endpoint config json path>
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory)] 
    [string]$ServiceEndpointJsonPath,
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
Write-Debug "${functionName}:ServiceEndpointJsonPath=$ServiceEndpointJsonPath"
Write-Debug "${functionName}:WorkingDirectory=$WorkingDirectory"

try {

    [System.IO.DirectoryInfo]$moduleDir = Join-Path -Path $WorkingDirectory -ChildPath "scripts/modules/ado"
    Write-Debug "${functionName}:moduleDir.FullName=$($moduleDir.FullName)"

    Import-Module $moduleDir.FullName -Force

    # Initialize az devops commands
    [string]$devopsOrgnizationUri = $env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI
    [string]$devopsProjectName = $env:SYSTEM_TEAMPROJECT
    [string]$devopsProjectId = $env:SYSTEM_TEAMPROJECTID
    Write-Debug "${functionName}:devopsOrgnizationUri=$devopsOrgnizationUri"
    Write-Debug "${functionName}:devopsProjectName=$devopsProjectName"
    Write-Debug "${functionName}:devopsProjectId=$devopsProjectId"
   
    $env:AZURE_DEVOPS_EXT_PAT = $env:SYSTEM_ACCESSTOKEN 
    az devops configure --defaults organization=$devopsOrgnizationUri project=$devopsProjectName

    # Define Azure DevOps variables
    $spiname = "ADO-DefraGovUK-ADP-SND1-ContUAA"
    $appId = "ea14266a-4d9e-4674-9f98-08d077ac8d93"
    $subscriptionId = "55f3b8c6-6800-41c7-a40d-2adb5e4e1bd1"
    $subsName = "AZD-ADP-SND1"
    $tenantID = "6f504113-6b64-43f2-ade9-242e05780007"
    $organization = "defragovuk"
    $project = "DEFRA-FFC"
    $serviceConnectionName = "test"

    # Define the service connection configuration
    $serviceConnectionConfig = @{
        "name" = $serviceConnectionName
        "type" = "azuresp"
        "url" = "https://management.azure.com/"
        "authorization" = @{
            "parameters" = @{
                "tenantid" = $tenantId
                "serviceprincipalid" = $appId
                "authenticationType" = "spnKey"
            }
            "scheme" = "ServicePrincipal"
        }
        "data" = @{
            "subscriptionId" = $subscriptionId
            "subscriptionName" = $subsName
        }
    }

    # Convert configuration to JSON
    $serviceConnectionConfigJson = $serviceConnectionConfig | ConvertTo-Json -Depth 10

    # Create the service connection
    az devops service-endpoint create --organization https://dev.azure.com/$organization --project $project --service-endpoint-configuration $serviceConnectionConfigJson


    
    if ($LASTEXITCODE -ne 0) {
        throw "Error configuring default devops organization=$devopsOrgnizationUri project=$devopsProjectName with exit code $LASTEXITCODE"
    }

    [PSCustomObject]$serviceEndpoints = Get-Content -Raw -Path $ServiceEndpointJsonPath | ConvertFrom-Json

    $functionInput = @{
        ProjectId      = $devopsProjectId
        ProjectName    = $devopsProjectName
        OrgnizationUri = $devopsOrgnizationUri
    }

    $serviceEndpoints.azureRMServiceConnections | Set-ServiceEndpoint @functionInput

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