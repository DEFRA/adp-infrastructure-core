<#
.SYNOPSIS
Initialize default headers With AccessToken.

.DESCRIPTION
Initialize default headers With AccessToken require to perform devops rest api call.

.PARAMETER PatToken
Optional. Pat Token with Service endpoint manage permission. 
If PatToken is not provided $env:SYSTEM_ACCESSTOKEN will be used. Make sure Project build service identity has granted 
required permissions to perform create or update service endpoint operatins.
For e.g. To create service connection in Defra-FFC project 'DEFRA-FFC Build Service (defragovuk)' identity should be granted 'Administrator' permissions at Service connection scope.

.EXAMPLE
.\Get-DefaultHeadersWithAccessToken
#> 
Function Get-DefaultHeadersWithAccessToken() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [string]$PatToken
    )

    [string]$functionName = $MyInvocation.MyCommand    
    Write-Debug "${functionName}:Entered"
    
    $accessTokenHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $accessTokenHeaders.Add("Content-Type", "application/json")
    
    if([string]::IsNullOrWhiteSpace($PatToken)) {
        $accessTokenHeaders.Add("Authorization", "Bearer $env:SYSTEM_ACCESSTOKEN")
    }
    else {
        $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PatToken)"))
        $accessTokenHeaders.Add("Authorization", "Basic $token")
    }
    
    Write-Debug "${functionName}:Exited"
    return $accessTokenHeaders
}