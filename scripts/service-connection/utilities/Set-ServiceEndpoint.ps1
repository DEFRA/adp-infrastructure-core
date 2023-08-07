<#
.SYNOPSIS
Create or Update an Azure RM service endpoint (ServiceConnection).

.DESCRIPTION
Create an Azure RM type service endpoint (ServiceConnection). It also verifies the service endpoint using endpointproxy.

.PARAMETER ArmServiceConnection
Mandatory. Service connection object(Coming from input config file)

.PARAMETER ProjectId
Mandatory. Azure devops project ID

.PARAMETER ProjectName
Mandatory. Azure devops project name

.PARAMETER OrgnizationUri
Mandatory. Azure devops project Orgnization Uri

.EXAMPLE
.\Set-ServiceEndpoint -ArmServiceConnection <ArmServiceConnectionObject> -ProjectId <ProjectID> -ProjectName <ProjectName> OrgnizationUri <OrgnizationUri>
#> 
Function Set-ServiceEndpoint() {
    [CmdletBinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline = $true)]
        [Object]$ArmServiceConnection,
        [Parameter(Mandatory)]
        [string]$ProjectId,
        [Parameter(Mandatory)]
        [string]$ProjectName,
        [Parameter(Mandatory)]
        [string]$OrgnizationUri
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand    
        Write-Debug "${functionName}:Entered"  
        Write-Debug "${functionName}:ProjectId=$ProjectId"
        Write-Debug "${functionName}:ProjectName=$ProjectName"
        Write-Debug "${functionName}:OrgnizationUri=$OrgnizationUri"     
    }

    process {    
        Write-Debug "${functionName}:ArmServiceConnection=$($ArmServiceConnection | ConvertTo-Json -Depth 10)"
        
        #$headers = Get-DefaultHeadersWithAccessToken -PatToken $env:SYSTEM_ACCESSTOKEN
        $headers = Get-DefaultHeadersWithAccessToken

        $serviceEndpointRequestBody = Initialize-RequestBody -ArmServiceConnection $ArmServiceConnection -ProjectId $ProjectId -ProjectName $ProjectName
       
        [string]$serviceEndpointName = $armServiceConnection.displayName
        Write-Debug "Check if $($serviceEndpointName) exists"
        [string]$existingServiceEndpointId = az devops service-endpoint list --query "[?name=='$serviceEndpointName'].id" -o tsv
        if ($LASTEXITCODE -ne 0) {
            throw "Error getting service endpoint Id for '$serviceEndpointName' using 'az devops service-endpoint list' command with exit code $LASTEXITCODE"
        }
        Write-Host "existingServiceEndpointId=$existingServiceEndpointId"
        
        if (-not $existingServiceEndpointId) {            
            [string]$createServiceEndpointUri = "$($OrgnizationUri)/$ProjectName/_apis/serviceendpoint/endpoints?api-version=7.0"
            Write-Host "Creating ServiceEndpoint $($serviceEndpointName). Post url = $($createServiceEndpointUri)"
            $response = Invoke-RestMethod -Uri $createServiceEndpointUri -Headers $headers -Method Post -Body $serviceEndpointRequestBody
            if ($LASTEXITCODE -ne 0) {
                throw "Error creating serviceEndpoint $($serviceEndpointName) with exit code $LASTEXITCODE"
            }

            Write-Host "Verifying ServiceEndpoint $($serviceEndpointName)"
            Test-ServiceEndpoint -ServiceEndpointId $response.id -ServiceEndpointRequestBody $serviceEndpointRequestBody -ProjectName $ProjectName -OrgnizationUri $OrgnizationUri
            Write-Host "ServiceEndpoint $($serviceEndpointName) Created and Verified succesfully. Service Endpoint Id = $($response.id)"
        }
        else {
            $existingServiceEndpointState = az devops service-endpoint list --query "[?name=='$serviceEndpointName']"
            if ($LASTEXITCODE -ne 0) {
                throw "Error getting service endpoint details for '$serviceEndpointName' using 'az devops service-endpoint list' command with exit code $LASTEXITCODE"
            }
            Write-Host "ServiceEndpoint state before Update : $(($existingServiceEndpointState | ConvertFrom-Json) | ConvertTo-Json -Depth 10)"

            [string]$updateServiceEndpointUri = "$($OrgnizationUri)/$ProjectName/_apis/serviceendpoint/endpoints/$($existingServiceEndpointId)?api-version=7.0"
            Write-Host "Updating ServiceEndpoint $($serviceEndpointName). Put url = $($updateServiceEndpointUri)"
            $response = Invoke-RestMethod -Uri $updateServiceEndpointUri -Headers $headers -Method Put -Body $serviceEndpointRequestBody
            if ($LASTEXITCODE -ne 0) {
                throw "Error updating serviceEndpoint $($serviceEndpointName) with exit code $LASTEXITCODE"
            }

            Write-Host "Verifying ServiceEndpoint $($serviceEndpointName)"
            Test-ServiceEndpoint -ServiceEndpointId $response.id -ServiceEndpointRequestBody $serviceEndpointRequestBody -ProjectName $ProjectName -OrgnizationUri $OrgnizationUri
            Write-Host "ServiceEndpoint $($serviceEndpointName) Updated and Verified succesfully. Service Endpoint Id = $($response.id)"
        }
    }

    end {
        Write-Debug "${functionName}:Exited"
    }    
}