<#
.SYNOPSIS
Create or Update an Azure RM type service endpoint (ServiceConnection).

.DESCRIPTION
Create an Azure RM type service endpoint (ServiceConnection). It also verifies the service endpoint using endpointproxy.

.PARAMETER ServiceEndpointJsonPath
Mandatory. Service connection configuration file.

.PARAMETER FederatedEndpointJsonPath
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
    [string]$FederatedEndpointJsonPath,
    [Parameter()]
    [string]$WorkingDirectory = $PWD
)

Function CreateServiceConnection() {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory)] 
        [string]$ServiceEndpointJsonPath,
        [Parameter()]
        [string]$workingDirectory = $PWD
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

        $functionInput = @{
            ProjectId      = $devopsProjectId
            ProjectName    = $devopsProjectName
            OrgnizationUri = $devopsOrgnizationUri
        }

        $serviceEndpoints.azureRMServiceConnections | Set-ServiceEndpoint @functionInput   
              
        CreateFederatedCredentialServiceConnection -federatedEndpointJsonPath $FederatedEndpointJsonPath -serviceEndpoints $serviceEndpoints -devopsOrgnizationUri $devopsOrgnizationUri -devopsProjectName $devopsProjectName -devopsProjectId $devopsProjectId

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
}

Function CreateFederatedCredentialServiceConnection() {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FederatedEndpointJsonPath,
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$serviceEndpoints,
        [Parameter(Mandatory = $true)]
        [string]$devopsOrgnizationUri,
        [Parameter(Mandatory = $true)]
        [string]$devopsProjectName,
        [Parameter(Mandatory = $true)]
        [string]$devopsProjectId, 
        [Parameter(Mandatory = $false)]
        [string]$graphApiversion = "v1.0"
    )
    
    $federatedServiceEndpoint = Get-Content -Raw -Path $FederatedEndpointJsonPath | ConvertFrom-Json
    $serviceConnectionName = $federatedServiceEndpoint.serviceEndpointProjectReferences[0].name
    Write-Host "Service connection name '$serviceConnectionName'"
    
    $serviceConnectionId = az devops service-endpoint list --org $devopsOrgnizationUri --project $devopsProjectName --query "[?name=='$serviceConnectionName'].id" -o tsv

    Write-Host "Service connection Id '$serviceConnectionId'"
    
    if ($serviceConnectionId) {
        Write-Output "ADO service connection $serviceConnectionName is already exist. No changes made."
    } else { 
        Write-Output "Creating ADO federated credential service connection $serviceConnectionName"

        $principalId = (az ad app list --display-name $serviceEndpoints.azureRMServiceConnections.appRegName | convertFrom-Json).appId
        Write-Host "The principalId is '$principalId'"

        $jsonObject = Get-Content $FederatedEndpointJsonPath -raw | ConvertFrom-Json
        $jsonObject.authorization.parameters.serviceprincipalid =  $principalId
        $jsonObject.serviceEndpointProjectReferences.projectReference | % {{$_.id=$devopsProjectId}}
        $jsonObject.serviceEndpointProjectReferences.projectReference | % {{$_.name=$devopsProjectName}}
        $jsonObject | ConvertTo-Json -depth 32| set-content $FederatedEndpointJsonPath        

        az devops service-endpoint create --service-endpoint-configuration $FederatedEndpointJsonPath --org $devopsOrgnizationUri --project $devopsProjectName
    }     
}

CreateServiceConnection -serviceEndpointJsonPath $ServiceEndpointJsonPath 
     