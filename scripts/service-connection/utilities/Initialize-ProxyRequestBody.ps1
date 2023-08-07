<#
.SYNOPSIS
Initialize service endpoint proxy request body To verify Service endpoint.

.DESCRIPTION
Initialize service endpoint proxy request body To verify Service endpoint. It uses default 'endpointproxy-request-body.json' file to prepare request body.
https://learn.microsoft.com/en-us/rest/api/azure/devops/serviceendpoint/endpointproxy/execute-service-endpoint-request?view=azure-devops-rest-7.1&tabs=HTTP#request-body

.PARAMETER ServiceEndpointRequestBody
Mandatory. Service Endpoint Request Body

.EXAMPLE
.\Initialize-ProxyRequestBody -ServiceEndpointRequestBody <ServiceEndpointRequestBody>
#> 
Function Initialize-ProxyRequestBody() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]$ServiceEndpointRequestBody
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand    
        Write-Debug "${functionName}:Entered"
    }

    process {        
        Write-Debug "Building Service endpoint proxy Body..."
        $serviceEndpointProxyDefaultConfig = Get-Content -Raw -Path '.\scripts\service-connection\request-body\endpointproxy-request-body.json' | ConvertFrom-Json
        Write-Debug "serviceEndpointProxyDefaultConfig = $($serviceEndpointProxyDefaultConfig | ConvertTo-Json -Depth 10)"

        $serviceEndpointProxyDefaultConfig.serviceEndpointDetails = ($ServiceEndpointRequestBody | ConvertFrom-Json)
        
        $serviceEndpointProxyRequestBody = $serviceEndpointProxyDefaultConfig | ConvertTo-Json -Depth 10
        #Do not print serviceEndpointProxyRequestBody as it contains password/sensitive info
        Write-Debug "ServiceEndpointProxy RequestBody Payload Initialized."
        return $serviceEndpointProxyRequestBody
    }

    end {
        Write-Debug "${functionName}:Exited"
    }    
}