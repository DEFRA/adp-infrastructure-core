<#
.SYNOPSIS
Verify service endpoint (ServiceConnection).

.DESCRIPTION
Verify service endpoint (ServiceConnection) is setup correctly using endpointproxy post api. This api returns 200(OK) response if configuration (for e.g. ServicePrincipal key or clientID) is 
correct or else returns 400.

.PARAMETER ServiceEndpointId
Mandatory. Service Endpoint Id.

.PARAMETER ServiceEndpointRequestBody
Mandatory. Service Endpoint Request Body

.PARAMETER ProjectName
Mandatory. Azure devops project name

.PARAMETER OrgnizationUri
Mandatory. Azure devops project Orgnization Uri

.EXAMPLE
.\Test-ServiceEndpoint -ServiceEndpointId <ServiceEndpointId> -ServiceEndpointRequestBody <ServiceEndpointRequestBody> -ProjectName <ProjectName> OrgnizationUri <OrgnizationUri>
#> 
Function Test-ServiceEndpoint() {
    [CmdletBinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline = $true)]
        [Object]$ServiceEndpointId,
        [Parameter(Mandatory)]
        [string]$ServiceEndpointRequestBody,
        [Parameter(Mandatory)]
        [string]$ProjectName,
        [Parameter(Mandatory)]
        [string]$OrgnizationUri
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand    
        Write-Debug "${functionName}:Entered" 
        Write-Debug "${functionName}:ServiceEndpointId=$ServiceEndpointId"
        Write-Debug "${functionName}:ProjectName=$ProjectName"
        Write-Debug "${functionName}:OrgnizationUri=$OrgnizationUri"     
    }

    process {            
        #$headers = Get-DefaultHeadersWithAccessToken -PatToken $env:SYSTEM_ACCESSTOKEN
        $headers = Get-DefaultHeadersWithAccessToken

        $serviceEndpointProxyRequestBody = Initialize-ProxyRequestBody -ServiceEndpointRequestBody $ServiceEndpointRequestBody
        
        [string]$endpointProxyServiceEndpointUri = "$($OrgnizationUri)/$ProjectName/_apis/serviceendpoint/endpointproxy?endpointId=$($ServiceEndpointId)&api-version=7.0"
        Write-Debug "Verifying ServiceEndpoint $($ServiceEndpointId). Put url = $($endpointProxyServiceEndpointUri)"
        $response = Invoke-RestMethod -Uri $endpointProxyServiceEndpointUri -Headers $headers -Method Post -Body $serviceEndpointProxyRequestBody
        if ($response.StatusCode -ne [system.net.httpstatuscode]::ok) {
            throw "Error Verifying serviceEndpoint $($ServiceEndpointId). ErrorMessage = $($response.errorMessage)"
        }
        Write-Debug "$($ServiceEndpointId) Verified. Service Endpoint Id = $($ServiceEndpointId)"
    }

    end {
        Write-Debug "${functionName}:Exited"
    }    
}