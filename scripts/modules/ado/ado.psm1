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
    
    [System.Collections.Generic.Dictionary[[String],[String]]]$accessTokenHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
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
        [PSCustomObject]$serviceEndpointProxyDefaultConfig = Get-Content -Raw -Path '.\scripts\ado\request-body\endpointproxy-request-body.json' | ConvertFrom-Json
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
        [PSCustomObject]$serviceEndpointDefaultConfig = Get-Content -Raw -Path '.\scripts\ado\request-body\arm-serviceendpoint-request-body.json' | ConvertFrom-Json
        Write-Debug "serviceEndpointDefaultConfig = $($serviceEndpointDefaultConfig | ConvertTo-Json -Depth 10)"

        $serviceEndpointDefaultConfig.name = $ArmServiceConnection.displayName
        $serviceEndpointDefaultConfig.description = $ArmServiceConnection.description

        $serviceEndpointDefaultConfig.data.subscriptionId = $ArmServiceConnection.subscriptionId
        $serviceEndpointDefaultConfig.data.subscriptionName = $ArmServiceConnection.subscriptionName
    
        $serviceEndpointDefaultConfig.authorization.parameters.tenantid = $ArmServiceConnection.tenantId


        [string]$kvClientIdSecretName = ($ArmServiceConnection.keyVault.secrets | Where-Object { $_.type -eq 'ClientId' }).key
        [string]$kvClientPasswordSecretName = ($ArmServiceConnection.keyVault.secrets | Where-Object { $_.type -eq 'ClientSecret' }).key
    
        Write-Host "Fetching Keyvault secret $($kvClientIdSecretName) from $($ArmServiceConnection.keyVault.name)"
        [string]$spClientId = az keyvault secret show --name $kvClientIdSecretName --vault-name $ArmServiceConnection.keyVault.name --query "value" -o tsv
        if ($LASTEXITCODE -ne 0) {
            throw "Error Fetching Keyvault secret $($kvClientIdSecretName) from $($ArmServiceConnection.keyVault.name) with exit code $LASTEXITCODE"
        }
        else {
            Write-Debug "spClientId=$spClientId"
        }
    
        Write-Host "Fetching Keyvault secret $($kvClientPasswordSecretName) from $($ArmServiceConnection.keyVault.name)"
        [string]$spClientPassword = az keyvault secret show --name $kvClientPasswordSecretName --vault-name $ArmServiceConnection.keyVault.name --query "value" -o tsv
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
        [PSCustomObject]$selfprojectReference = New-Object -TypeName PSObject -Property @{ id = $ProjectId ; name = $ProjectName }
        [PSCustomObject]$currentProjectReference = New-Object -TypeName PSObject -Property @{ description = $ArmServiceConnection.description ; name = $ArmServiceConnection.displayName ; projectReference = $selfprojectReference }
        $serviceEndpointDefaultConfig.serviceEndpointProjectReferences = @( $currentProjectReference )

        [string]$serviceEndpointRequestBody = $serviceEndpointDefaultConfig | ConvertTo-Json -Depth 10
        #Do not print serviceEndpointRequestBody as it contains password/sensitive info
        Write-Debug "ServiceEndpointProxy RequestBody Payload Initialized"
        return $serviceEndpointRequestBody
    }

    end {
        Write-Debug "${functionName}:Exited"
    }    
}

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
        
        #Enable this when locally testing with Pat Token    
        # [Object]$headers = Get-DefaultHeadersWithAccessToken -PatToken $env:SYSTEM_ACCESSTOKEN
        
        [Object]$headers = Get-DefaultHeadersWithAccessToken

        [string]$serviceEndpointRequestBody = Initialize-RequestBody -ArmServiceConnection $ArmServiceConnection -ProjectId $ProjectId -ProjectName $ProjectName
       
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
            [Object]$response = Invoke-RestMethod -Uri $createServiceEndpointUri -Headers $headers -Method Post -Body $serviceEndpointRequestBody
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
            [Object]$response = Invoke-RestMethod -Uri $updateServiceEndpointUri -Headers $headers -Method Put -Body $serviceEndpointRequestBody
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
        #Enable this when locally testing with Pat Token    
        # [Object]$headers = Get-DefaultHeadersWithAccessToken -PatToken $env:SYSTEM_ACCESSTOKEN

        [Object]$headers = Get-DefaultHeadersWithAccessToken

        [string]$serviceEndpointProxyRequestBody = Initialize-ProxyRequestBody -ServiceEndpointRequestBody $ServiceEndpointRequestBody
        
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



<#
.SYNOPSIS
Trigger a new Build.

.DESCRIPTION
This function will trigger a new build and wait till it's completed.

.PARAMETER organisationUri
Mandatory. Azure devops project Orgnization Uri

.PARAMETER projectName
Mandatory. Azure devops project name

.PARAMETER buildDefinitionId
Mandatory. Build Definition Id

.PARAMETER requestBody
Mandatory. Request Body

.EXAMPLE
.\New-BuildRun -organisationUri <organisationUri> -projectName <projectName> -buildDefinitionId <buildDefinitionId> -requestBody <requestBody>
#> 
Function New-BuildRun() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]$organisationUri,
        [Parameter(Mandatory)]
        [string]$projectName,
        [Parameter(Mandatory)]
        [int]$buildDefinitionId,
        [Parameter(Mandatory)]
        [string]$requestBody
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand
        Write-Host "${functionName} started at $($startTime.ToString('u'))"
        Write-Debug "${functionName}:organisationUri=$organisationUri"
        Write-Debug "${functionName}:projectName=$projectName"
        Write-Debug "${functionName}:buildDefinitionId=$buildDefinitionId"
        Write-Debug "${functionName}:requestBody=$requestBody"
    }

    process {
        # [Object]$headers = Get-DefaultHeadersWithAccessToken
        [Object]$headers = Get-DefaultHeadersWithAccessToken -PatToken 'p4kenbwg2ug6yxgnbwirvtnftrkyfr3uduhuabue4ateaetzd26q'

        $uriPostRunPipeline = "$($organisationUri)$($projectName)/_apis/pipelines/$($buildDefinitionId)/runs?api-version=7.0"
        Write-Host "uriPostRunPipeline: $uriPostRunPipeline"

        [Object]$pipelineRun = Invoke-RestMethod -Uri $uriPostRunPipeline -Method Post -Headers $headers -Body $requestBody
        # [string]$command = "Invoke-RestMethod -Uri $uriPostRunPipeline -Method Post -Headers $headers -Body '$requestBody'"
        # Write-Host $command
        # [object]$pipelineRun = Invoke-CommandLine -Command $command

        if ($LASTEXITCODE -ne 0) {
            throw "Error queuing the build for the definitionid '$buildDefinitionId' for project '$projectName' command with exit code $LASTEXITCODE"
        }
        Write-Debug ($pipelineRun | Out-String)
        Write-Debug "Pipeline runId $($pipelineRun.id) triggered sucessfully. Current state: $($pipelineRun.state)"

        $piplineRunResult = [string]::Empty
        $totalSleepinSec = 0
        $pipelineStateCheckMaxWaitTimeOutInSec = 600
        do {
            Start-Sleep -Seconds 60
            $gerPipelineRunStateUri = "$($organisationUri)$($projectName)/_apis/pipelines/$($buildDefinitionId)/runs/$($pipelineRun.id)?api-version=7.0"
            $pipelinerundetails = Invoke-RestMethod -Uri $gerPipelineRunStateUri -Method Get -Headers $headers
            if ($LASTEXITCODE -ne 0) {
                throw "Error reading the pipeline runId '$($pipelineRun.id)' status with exit code $LASTEXITCODE"
            }
            $currentState = $pipelinerundetails.state
            Write-Host "Current state of pipeline runId $($pipelineRun.id): $($currentState)"
            Write-Host "Running state check..."
            if ($currentState -ne "inProgress") {
                $piplineRunResult = $pipelinerundetails.result
                Write-Host "Current state: $($currentState)"
                break
            }
        } until ($currentState -ne "inProgress" -or $totalSleepinSec -ge $pipelineStateCheckMaxWaitTimeOutInSec)

        #report pipeline status
        if ($piplineRunResult -eq "succeeded") {
            $successmsg = "$($pipelinerundetails.pipeline.name) pipeline with runId $($pipelinerundetails.id) has completed successfully."
            Write-Host "$($successmsg)"
        }
        else {
            if ($totalSleepinSec -ge $pipelineStateCheckMaxWaitTimeOutInSec) {
                $errorMsg += "Excecution of pipeline has stopped due to max timeout of $($pipelineStateCheckMaxWaitTimeOutInSec) sec."
            }
            else {
                $errormsg = "$($pipelinerundetails.pipeline.name) pipeline with runId $($pipelinerundetails.id) has failed."
            }
            Write-Host "##vso[task.logissue type=error]$($errormsg)"
            exit 1
        }
    }
    end {
        Write-Debug "${functionName}:Exited"
    }
}