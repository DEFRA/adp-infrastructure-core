<#
.SYNOPSIS
Create an Azure RM type service endpoint (ServiceConnection).

.DESCRIPTION
Create an Azure RM type service endpoint (ServiceConnection).

.PARAMETER ServiceConnectionJsonPath
Mandatory. Service connection configuration file.

.EXAMPLE
.\Initialize-ServiceConnection-API.ps1 -ServiceConnectionJsonPath <Service connection config json path>
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory)] 
    [string] $ServiceConnectionJsonPath = '.\infra\config\service-connections\tier2-service-connection-pat.json'
)

Function Initialize-RequestBody() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object]$ArmServiceConnection
    )

    [string]$functionName = $MyInvocation.MyCommand    
    Write-Debug "${functionName}:Entered"
    Write-Debug "${functionName}:ArmServiceConnection=$($ArmServiceConnection | ConvertTo-Json -Depth 10)" -Debug

    Write-Debug "Building Service connection Body for $($ArmServiceConnection.displayName)..." -Debug
    $serviceConnectionDefaultConfig = Get-Content -Raw -Path '.\scripts\service-connection\request-body.json' | ConvertFrom-Json
    Write-Debug "serviceConnectionDefaultConfig = $($serviceConnectionDefaultConfig | ConvertTo-Json -Depth 10)" -Debug

    $serviceConnectionDefaultConfig.name = $ArmServiceConnection.displayName
    $serviceConnectionDefaultConfig.description = $ArmServiceConnection.description

    $serviceConnectionDefaultConfig.data.subscriptionId = $ArmServiceConnection.subscriptionId
    $serviceConnectionDefaultConfig.data.subscriptionName = $ArmServiceConnection.subscriptionName
    
    $serviceConnectionDefaultConfig.authorization.parameters.tenantid = $ArmServiceConnection.tenantId


    $kvClientIdSecretName = ($ArmServiceConnection.keyVault.secrets | Where-Object {$_.type -eq 'ClientId'}).key
    $kvClientPasswordSecretName = ($ArmServiceConnection.keyVault.secrets | Where-Object {$_.type -eq 'ClientSecret'}).key
    
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

    $serviceConnectionDefaultConfig.authorization.parameters.serviceprincipalid = $spClientId
    $serviceConnectionDefaultConfig.authorization.parameters.serviceprincipalkey = $spClientPassword

    if(-not [string]::IsNullOrWhiteSpace($ArmServiceConnection.isShared)) {
        $serviceConnectionDefaultConfig.isShared = $ArmServiceConnection.isShared
    }
    
    #Set current ProjectReference to service endpoint
    $serviceConnectionDefaultConfig.serviceEndpointProjectReferences = $null
    $selfprojectReference = New-Object -TypeName PSObject -Property @{ id = $DevopsProjectId ; name = $DevopsProjectName }
    $currentProjectReference = New-Object -TypeName PSObject -Property @{ description = $ArmServiceConnection.description ; name = $ArmServiceConnection.displayName ; projectReference = $selfprojectReference }
    $serviceConnectionDefaultConfig.serviceEndpointProjectReferences = @( $currentProjectReference )

    $serviceConnectionRequestBody = $serviceConnectionDefaultConfig | ConvertTo-Json -Depth 10
    Write-Debug "Payload: $($serviceConnectionRequestBody)" -Debug

    Write-Debug "${functionName}:Exited"
    return $serviceConnectionRequestBody
}

Function Get-DefaultHeadersWithAccessToken() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$PatToken
    )

    $accessTokenHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $accessTokenHeaders.Add("Content-Type", "application/json")
    
    if([string]::IsNullOrWhiteSpace($PatToken)) {
        $accessTokenHeaders.Add("Authorization", "Bearer $env:SYSTEM_ACCESSTOKEN")
    }
    else {
        $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PatToken)"))
        $accessTokenHeaders.Add("Authorization", "Basic $token")
    }
   
    return $accessTokenHeaders
}

Function Set-ServiceConnections() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceConnectionJsonPath
    )

    [string]$functionName = $MyInvocation.MyCommand    
    Write-Debug "${functionName}:Entered"
    Write-Debug "${functionName}:ServiceConnectionJsonPath=$ServiceConnectionJsonPath" -Debug

    $serviceConnections = Get-Content -Raw -Path $ServiceConnectionJsonPath | ConvertFrom-Json
    
    # $headers = Get-DefaultHeadersWithAccessToken
    $headers = Get-DefaultHeadersWithAccessToken -PatToken $env:SYSTEM_ACCESSTOKEN #for local testing
    $createServiceendpointUri = "$($DevopsOrgnizationUri)/$DevopsProjectName/_apis/serviceendpoint/endpoints?api-version=7.0"

    foreach ($armServiceConnection in $serviceConnections.azureRMServiceConnections) {

        $serviceConnectionRequestBody = Initialize-RequestBody -ArmServiceConnection $armServiceConnection
       
        $ServiceEndpointName = $armServiceConnection.displayName
        Write-Debug "Check if $($ServiceEndpointName) exists"
        $isServiceEndpointAlreadyExist = az devops service-endpoint list --query "[?name=='$ServiceEndpointName'].id" -o tsv
        if ($LASTEXITCODE -ne 0) {
            throw "Error getting service endpoint '$ServiceEndpointName' details using 'az devops service-endpoint list' command with exit code $LASTEXITCODE"
        }
        Write-Debug "isServiceEndpointAlreadyExist=$isServiceEndpointAlreadyExist"
        
        if (-not $isServiceEndpointAlreadyExist) {
            Write-Host "Creating ServiceEndpointName $($ServiceEndpointName).."
            $response = Invoke-RestMethod -Uri $createServiceendpointUri -Headers $headers -Method Post -Body $serviceConnectionRequestBody -Debug
            Write-Host "LASTEXITCODE = $LASTEXITCODE"
            Write-Debug "$($ServiceEndpointName) Created. Service Endppoint Id = $($response.id)"
        }
        else {
            Write-Host "Updating ServiceEndpointName $($ServiceEndpointName).."
            #Pending
        }
    }

    Write-Debug "${functionName}:Exited"
}


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
Write-Debug "${functionName}:ServiceConnectionJsonPath=$ServiceConnectionJsonPath"

try {

    # Initialize az devops commands
    $DevopsOrgnizationUri = $env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI
    $DevopsProjectName = $env:SYSTEM_TEAMPROJECT
    $DevopsProjectId = $env:SYSTEM_TEAMPROJECTID
    Write-Debug "${functionName}:DevopsOrgnizationUri=$DevopsOrgnizationUri"
    Write-Debug "${functionName}:DevopsProjectName=$DevopsProjectName"
   
    $env:AZURE_DEVOPS_EXT_PAT = $env:SYSTEM_ACCESSTOKEN 
    az devops configure --defaults organization=$DevopsOrgnizationUri project=$DevopsProjectName
    Write-Host "LASTEXITCODE = $LASTEXITCODE"

    Set-ServiceConnections -ServiceConnectionJsonPath $ServiceConnectionJsonPath
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