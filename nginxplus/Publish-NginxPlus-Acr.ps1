[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $AcrName,
    [Parameter(Mandatory)]
    [string] $AzureSubscription,
    [Parameter(Mandatory)]
    [string] $KeyVaultName,
    [Parameter(Mandatory)]
    [string] $NGINXCertSecretName,
    [Parameter(Mandatory)]
    [string] $NGINXKeySecretName,
    [Parameter(Mandatory)]
    [string] $CertFilesPath,
    [Parameter(Mandatory)]
    [string] $NGINXVersion
)

function Save-SecretToFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$VaultName,
        [Parameter(Mandatory)]
        [string]$SecretName,
        [Parameter(Mandatory)]
        [string]$OutputFilePath
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand
        Write-Debug "${functionName}:Entered"
        Write-Debug "${functionName}:VaultName=$VaultName"
        Write-Debug "${functionName}:SecretName=$SecretName"
        Write-Debug "${functionName}:OutputFilePath=$OutputFilePath"
    }

    process {
        Write-Host "Downloading secret $SecretName from $VaultName to $OutputFilePath"
        [string]$secretValue = Get-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName -AsPlainText
        Write-Host "Secret value length: $($secretValue.Length)"
        
        Set-Content -Path $OutputFilePath -Value $secretValue -Encoding utf8
        Write-Host "Secret value saved to $OutputFilePath"
    }
    
    end {
        Write-Debug "${functionName}:Exited"
    }
}

function Get-Image {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $KeyVaultName,
        [Parameter(Mandatory)]
        [string] $NGINXCertSecretName,
        [Parameter(Mandatory)]
        [string] $NGINXKeySecretName,
        [Parameter(Mandatory)]
        [string] $NGINXVersion
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand
        Write-Debug "${functionName}:Entered"
        Write-Debug "${functionName}:KeyVaultName=$KeyVaultName"
        Write-Debug "${functionName}:NGINXCertSecretName=$NGINXCertSecretName"
        Write-Debug "${functionName}:NGINXKeySecretName=$NGINXKeySecretName"
        Write-Debug "${functionName}:NGINXVersion=$NGINXVersion"
    }

    process {

        [string]$clientCertPath = Join-Path -Path $CertFilesPath -ChildPath "client.cert"
        Save-SecretToFile -VaultName $KeyVaultName -SecretName $NGINXCertSecretName -OutputFilePath $clientCertPath
        
        [string]$clientKeyPath = Join-Path -Path $CertFilesPath -ChildPath "client.key"
        Save-SecretToFile -VaultName $KeyVaultName -SecretName $NGINXKeySecretName -OutputFilePath $clientKeyPath

        [string]$dockerCertDir = "/etc/docker/certs.d/private-registry.nginx.com"
        [string]$mkdirCommand = "sudo mkdir -p $dockerCertDir"
        Write-Host $mkdirCommand
        Invoke-CommandLine -Command $mkdirCommand | Out-Null

        [string]$dockerClientCertPath = Join-Path -Path $dockerCertDir -ChildPath "client.cert"
        [string]$mvClientCertCommand = "sudo mv $clientCertPath $dockerClientCertPath"
        Write-Host $mvClientCertCommand
        Invoke-CommandLine -Command $mvClientCertCommand | Out-Null
            
        [string]$dockerClientKeyPath = Join-Path -Path "/etc/docker/certs.d/private-registry.nginx.com" -ChildPath "client.key"
        [string]$mvKeyCertCommand = "sudo mv $clientKeyPath $dockerClientKeyPath"
        Write-Host $mvKeyCertCommand
        Invoke-CommandLine -Command $mvKeyCertCommand | Out-Null
        
        [string]$dockerPullCommand = "docker pull private-registry.nginx.com/nginx-ic/nginx-plus-ingress:$NGINXVersion"
        Write-Host $dockerPullCommand
        Invoke-CommandLine -Command $dockerPullCommand | Out-Null
    }
    
    end {
        Write-Debug "${functionName}:Exited"
    }
}

function Publish-Image {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string] $AcrName,
        [Parameter(Mandatory)]
        [string] $NGINXVersion
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand
        Write-Debug "${functionName}:Entered"
        Write-Debug "${functionName}:AcrName=$AcrName"
        Write-Debug "${functionName}:NGINXVersion=$NGINXVersion"
    }

    process {

        [string]$acrLoginCommand = "az acr login --name $AcrName"
        Write-Host $acrLoginCommand
        Invoke-CommandLine -Command $acrLoginCommand | Out-Null

        [string]$publishingTarget = '{0}.azurecr.io/{1}:{2}' -f $AcrName, "image/nginx-plus-ingress", $NGINXVersion
        [string]$dockerTagCommand = "docker tag private-registry.nginx.com/nginx-ic/nginx-plus-ingress:$NGINXVersion $publishingTarget"
        Write-Host $dockerTagCommand
        Invoke-CommandLine -Command $dockerTagCommand | Out-Null

        if ($PSCmdlet.ShouldProcess("Publish NGINX Image to Acr, Publish target:$($publishingTarget)", 'Publish')) {
            [string]$dockerPushCommand = "docker push $publishingTarget"
            Write-Host $dockerPushCommand
            Invoke-CommandLine -Command $dockerPushCommand | Out-Null
        }
    }
    end {
        Write-Debug "${functionName}:Exited"
    }
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
Write-Debug "${functionName}:AcrName=$AcrName"
Write-Debug "${functionName}:AzureSubscription=$AzureSubscription"
Write-Debug "${functionName}:KeyVaultName=$KeyVaultName"
Write-Debug "${functionName}:NGINXCertSecretName=$NGINXCertSecretName"
Write-Debug "${functionName}:NGINXKeySecretName=$NGINXKeySecretName"
Write-Debug "${functionName}:CertFilesPath=$CertFilesPath"
Write-Debug "${functionName}:NGINXVersion=$NGINXVersion"

try {

    Install-Module -Name "Az.Accounts" -RequiredVersion "2.2.3" -Force -SkipPublisherCheck -AllowClobber
    Install-Module -Name "Az.KeyVault" -RequiredVersion "4.10.2" -Force -SkipPublisherCheck -AllowClobber

    [System.IO.DirectoryInfo]$rootDir = ($PSCommandPath | Split-Path -Parent) | Split-Path -Parent
    Write-Debug "${functionName}:rootDir.FullName=$($rootDir.FullName)"

    [System.IO.DirectoryInfo]$moduleDir = Join-Path -Path $scriptDir.FullName -ChildPath "scripts/modules/ps-helpers"
    Write-Debug "${functionName}:moduleDir.FullName=$($moduleDir.FullName)"
    Import-Module $moduleDir.FullName -Force

    Write-Host "${functionName}:Connecting to Azure..."
    [SecureString]$SecuredPassword = ConvertTo-SecureString -AsPlainText -String $env:servicePrincipalKey
    [PSCredential]$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $env:servicePrincipalId, $SecuredPassword
    $null = Connect-AzAccount -ServicePrincipal -TenantId $env:tenantId -Credential $Credential
    $null = Set-AzContext -Subscription $AzureSubscription
    Write-Host "${functionName}:Connected to Azure and set context to '$AzureSubscription'"
    
    Get-Image -KeyVaultName $KeyVaultName -NGINXCertSecretName $NGINXCertSecretName -NGINXKeySecretName $NGINXKeySecretName -NGINXVersion $NGINXVersion

    Publish-Image -AcrName $AcrName.ToLower() -NGINXVersion $NGINXVersion

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
