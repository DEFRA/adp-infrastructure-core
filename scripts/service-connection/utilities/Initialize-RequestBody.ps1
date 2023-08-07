<#
.SYNOPSIS
Initialize service endpoint request body To create or update Service endpoint of ARM type. 

.DESCRIPTION
Initialize request body To create or update Service endpoint of ARM type. It uses default 'arm-serviceendpoint-request-body.json' file to prepare request body.
https://learn.microsoft.com/en-us/rest/api/azure/devops/serviceendpoint/endpoints/create?tabs=HTTP#request-body

.PARAMETER ArmServiceConnection
Mandatory. Service connection object(Coming from input config file)

.PARAMETER ProjectId
Mandatory. Azure devops project ID

.PARAMETER ProjectName
Mandatory. Azure devops project name

.EXAMPLE
.\Initialize-RequestBody -ArmServiceConnection <ArmServiceConnectionObject> -ProjectId <ProjectID> -ProjectName <ProjectName>
#> 
Function Initialize-RequestBody() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object]$ArmServiceConnection,
        [Parameter(Mandatory)]
        [string]$ProjectId,
        [Parameter(Mandatory)]
        [string]$ProjectName
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand    
        Write-Debug "${functionName}:Entered"
        Write-Debug "${functionName}:ArmServiceConnection=$($ArmServiceConnection | ConvertTo-Json -Depth 10)"
        Write-Debug "${functionName}:ProjectId=$ProjectId"
        Write-Debug "${functionName}:ProjectName=$ProjectName"
    }

    process {        
        Write-Debug "Building Service connection Body for $($ArmServiceConnection.displayName)..."
        $serviceEndpointDefaultConfig = Get-Content -Raw -Path '.\scripts\service-connection\request-body\arm-serviceendpoint-request-body.json' | ConvertFrom-Json
        Write-Debug "serviceEndpointDefaultConfig = $($serviceEndpointDefaultConfig | ConvertTo-Json -Depth 10)"

        $serviceEndpointDefaultConfig.name = $ArmServiceConnection.displayName
        $serviceEndpointDefaultConfig.description = $ArmServiceConnection.description

        $serviceEndpointDefaultConfig.data.subscriptionId = $ArmServiceConnection.subscriptionId
        $serviceEndpointDefaultConfig.data.subscriptionName = $ArmServiceConnection.subscriptionName
    
        $serviceEndpointDefaultConfig.authorization.parameters.tenantid = $ArmServiceConnection.tenantId


        $kvClientIdSecretName = ($ArmServiceConnection.keyVault.secrets | Where-Object { $_.type -eq 'ClientId' }).key
        $kvClientPasswordSecretName = ($ArmServiceConnection.keyVault.secrets | Where-Object { $_.type -eq 'ClientSecret' }).key
    
        Write-Host "Fetching Keyvault secret $($kvClientIdSecretName) from $($ArmServiceConnection.keyVault.name)"
        $spClientId = az keyvault secret show --name $kvClientIdSecretName --vault-name $ArmServiceConnection.keyVault.name --query "value" -o tsv
        if ($LASTEXITCODE -ne 0) {
            throw "Error Fetching Keyvault secret $($kvClientIdSecretName) from $($ArmServiceConnection.keyVault.name) with exit code $LASTEXITCODE"
        }
        else {
            Write-Debug "spClientId=$spClientId"
        }
    
        Write-Host "Fetching Keyvault secret $($kvClientPasswordSecretName) from $($ArmServiceConnection.keyVault.name)"
        $spClientPassword = az keyvault secret show --name $kvClientPasswordSecretName --vault-name $ArmServiceConnection.keyVault.name --query "value" -o tsv
        if ($LASTEXITCODE -ne 0) {
            throw "Error Fetching Keyvault secret $($kvClientPasswordSecretName) from $($ArmServiceConnection.keyVault.name) with exit code $LASTEXITCODE"
        }

        $serviceEndpointDefaultConfig.authorization.parameters.serviceprincipalid = $spClientId
        $serviceEndpointDefaultConfig.authorization.parameters.serviceprincipalkey = $spClientPassword

        if (-not [string]::IsNullOrWhiteSpace($ArmServiceConnection.isShared)) {
            $serviceEndpointDefaultConfig.isShared = $ArmServiceConnection.isShared
        }
    
        #Set current ProjectReference to service endpoint
        $serviceEndpointDefaultConfig.serviceEndpointProjectReferences = $null
        $selfprojectReference = New-Object -TypeName PSObject -Property @{ id = $ProjectId ; name = $ProjectName }
        $currentProjectReference = New-Object -TypeName PSObject -Property @{ description = $ArmServiceConnection.description ; name = $ArmServiceConnection.displayName ; projectReference = $selfprojectReference }
        $serviceEndpointDefaultConfig.serviceEndpointProjectReferences = @( $currentProjectReference )

        $serviceEndpointRequestBody = $serviceEndpointDefaultConfig | ConvertTo-Json -Depth 10
        #Do not print serviceEndpointRequestBody as it contains password/sensitive info
        Write-Debug "ServiceEndpointProxy RequestBody Payload Initialized"
        return $serviceEndpointRequestBody
    }

    end {
        Write-Debug "${functionName}:Exited"
    }    
}