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
    [Parameter(Mandatory)] 
    [string]$FederatedEndpointJsonPath,
    [Parameter(Mandatory = $false)]
    [bool]$federatedCredential,
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
Write-Debug "${functionName}:FederatedEndpointJsonPath=$FederatedEndpointJsonPath"
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
    if ($LASTEXITCODE -ne 0) {
        throw "Error configuring default devops organization=$devopsOrgnizationUri project=$devopsProjectName with exit code $LASTEXITCODE"
    }

    [PSCustomObject]$serviceEndpoints = Get-Content -Raw -Path $ServiceEndpointJsonPath | ConvertFrom-Json
    if($federatedCredential -eq $False)
    {       
        $functionInput = @{
            ProjectId      = $devopsProjectId
            ProjectName    = $devopsProjectName
            OrgnizationUri = $devopsOrgnizationUri
        }    
        $serviceEndpoints.azureRMServiceConnections | Set-ServiceEndpoint @functionInput   
    }
    else {       

        $appReg = Get-AzADApplication -DisplayName $serviceEndpoints.azureRMServiceConnections.appRegName   

        $federatedCredentials = Get-AzADAppFederatedCredential -ApplicationObjectId $appReg.id
        $federatedCredentials | Select-Object -Property Name

        $ficName =  $serviceEndpoints.azureRMServiceConnections.displayName
        $federatedCredentialName = ""
        foreach ($credential in $federatedCredentials) {
            if($ficName -eq $credential.Name) {
                $federatedCredentialName = $credential.Name
                break
            }                
        }

        $functionInput = @{
            FederatedEndpointJsonPath =  $FederatedEndpointJsonPath
            FederatedCredentialName = $federatedCredentialName
            ServiceConnectionName = $ficName
            AppRegId = $appReg.id
            ProjectName    = $devopsProjectName
            OrgnizationUri = $devopsOrgnizationUri
        }        
        $serviceEndpoints.azureRMServiceConnections | Set-FederatedServiceEndpoint @functionInput
    }   

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