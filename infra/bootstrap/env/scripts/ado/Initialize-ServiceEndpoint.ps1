<#
.SYNOPSIS
Create or Update an Azure RM type service endpoint (ServiceConnection).

.DESCRIPTION
Create an Azure RM type service endpoint (ServiceConnection). It also verifies the service endpoint using endpointproxy.

.PARAMETER ServiceEndpointJsonPath
Mandatory. Service connection configuration file.

.PARAMETER EndpointJsonPath
Mandatory. Connection configuration file.

.PARAMETER WorkingDirectory
Optional. Working directory. Default is $PWD.

.EXAMPLE
.\Initialize-ServiceEndpoint.ps1 -ServiceEndpointJsonPath <Service endpoint config json path>
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory)] 
    [string]$ServiceEndpointJsonPath,
    [Parameter(Mandatory)] 
    [string]$EndpointJsonPath,
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
Write-Debug "${functionName}:EndpointJsonPath=$EndpointJsonPath"
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
    #$env:AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY="mysecrete12345666"
    az devops configure --defaults organization=$devopsOrgnizationUri project=$devopsProjectName

    az devops service-endpoint create --service-endpoint-configuration $EndpointJsonPath --org https://dev.azure.com/defragovuk/ --project DEFRA-FFC

    $appObjectId = "ea14266a-4d9e-4674-9f98-08d077ac8d93"
    New-AzADAppFederatedCredential -ApplicationObjectId $appObjectId -Audience api://AzureADTokenExchange -Issuer https://vstoken.dev.azure.com/0843dc02-bf94-4c0c-b0ed-bb5f8c829f46 -name 'testing04' -Subject 'sc://defragovuk/DEFRA-FFC/WorkloadIdentityFederation-svc2'


    # Define Azure DevOps variables
    #$spiname = "ADO-DefraGovUK-ADP-SND1-ContUAA"
    #$appId = "bd055de4-122a-45ed-bccd-79d950d069ed"
    #$subscriptionId = "55f3b8c6-6800-41c7-a40d-2adb5e4e1bd1"
    #$subsName = "AZD-ADP-SND1"
    #$tenantID = "6f504113-6b64-43f2-ade9-242e05780007"
    #$serviceConnectionName = "test05"  

    #az devops service-endpoint azurerm create --azure-rm-service-principal-id $appId --azure-rm-subscription-id $subscriptionId --azure-rm-subscription-name $subsName  --azure-rm-tenant-id  $tenantID  --name  $serviceConnectionName --org $devopsOrgnizationUri --project $devopsProjectName
    #az devops service-endpoint azurerm create --azure-rm-service-principal-id "xxxxx6d26a31435cb" --azure-rm-subscription-id "xxxxx7cb2a7" --azure-rm-subscription-name "xxx subscription" --azure-rm-tenant-id "xxxxx-af9038592395" --name "AzureSp"


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