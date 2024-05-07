<#
.SYNOPSIS
     Adds the supplied GitHub Repository to an installed App Installation
.DESCRIPTION
    Adds the supplied GitHub Repository to an installed App Installation. Used for when App Installations are selected repos only.
.PARAMETER AppId
    Mandatory. Github App Id Secret Name
.PARAMETER AppKey
    Mandatory. Github App Private Key Secret Name
.PARAMETER Environment
    Mandatory. Application Environment for Key Title
.PARAMETER SSHPublicKeySecretName
    Mandatory. Key Vault secret name for the SSH key
.PARAMETER PSHelperDirectory
    Mandatory. Directory Path of PSHelper module
.EXAMPLE
    .\Add-SshKeyToGitHubRepo.ps1 -AppId <AppId> -AppKey <AppKey> -Environment <Environment> `
        -SSHPublicKeySecretName <SSHPublicKeySecretName> -GitHubOrganisation <GitHubOrganisation> -GitHubRepository <GitHubRepository>
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$AppId,
    [Parameter(Mandatory)]
    [string]$AppKey,
    [Parameter(Mandatory)]
    [string]$Environment,
    [Parameter(Mandatory)]
    [string]$SSHPublicKeySecretName,
    [Parameter(Mandatory)]
    [string]$KeyVaultName,
    [Parameter()]
    [string]$GitHubOrganisation ='defra',
    [Parameter()]
    [string]$GitHubRepository = 'adp-flux-services',
    [Parameter()]
    [string]$PSHelperDirectory
)

function Get-GithubJwt {
    param(
        [Parameter(Mandatory)]
        [string]$AppId,
        [Parameter(Mandatory)]
        [string]$AppKey
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand
        Write-Debug "${functionName}:Entered"
        Write-Debug "${functionName}:AppId=$AppId"
    }
    process {
        $appKey = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($AppKey))
        
        $header = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject @{
            alg = "RS256"
            typ = "JWT"
            }))).TrimEnd('=').Replace('+', '-').Replace('/', '_');

        $payload = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject @{
                iat = [System.DateTimeOffset]::UtcNow.AddSeconds(-10).ToUnixTimeSeconds()
                exp = [System.DateTimeOffset]::UtcNow.AddMinutes(5).ToUnixTimeSeconds()
                iss = $AppId
            }))).TrimEnd('=').Replace('+', '-').Replace('/', '_');

        $rsa = [System.Security.Cryptography.RSA]::Create()
        $rsa.ImportFromPem($appKey)

        $signature = [Convert]::ToBase64String($rsa.SignData([System.Text.Encoding]::UTF8.GetBytes("$header.$payload"), [System.Security.Cryptography.HashAlgorithmName]::SHA256, [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)).TrimEnd('=').Replace('+', '-').Replace('/', '_')
        $jwt = "$header.$payload.$signature"
        return $jwt
    }

    end {
        Write-Debug "${functionName}:Exited"
    }
}

function Get-InstallationToken {
    param(
        [Parameter(Mandatory)]
        [string]$GitHubJwtToken
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand
        Write-Debug "${functionName}:Entered"
        Write-Debug "${functionName}:GitHubJwtToken=$GitHubJwtToken"
    }
    process {
        $headers = @{
            "Authorization"        = "Bearer $GitHubJwtToken"
            "Accept"               = "application/vnd.github+json"
            "X-GitHub-Api-Version" = "2022-11-28"
        }
    
        Write-Debug "Get App Installation ID..."
        [Object]$installation = Invoke-RestMethod -Method Get -Uri $appInstallationUrl -Headers $headers
        [string]$installationId = $installation.id
    
        Write-Debug "Get Installation Token..."
        [object]$instToken = Invoke-RestMethod -Method Post -Uri "$appInstallationUrl/$installationId/access_tokens" -Headers $headers
        return $instToken.token
    }

    end {
        Write-Debug "${functionName}:Exited"
    }
}

function Set-NewDeployKey {
    param(
        [Parameter(Mandatory)]
        [string]$InstallationToken,
        [Parameter(Mandatory)]
        [string]$Environment,
        [Parameter(Mandatory)]
        [string]$DeployKey
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand
        Write-Debug "${functionName}:Entered"
        Write-Debug "${functionName}:InstallationToken=$InstallationToken"
        Write-Debug "${functionName}:Environment=$Environment"
    }
    process {
        $headers = @{
            "Authorization"        = "Token $InstallationToken"
            "Accept"               = "application/vnd.github+json"
            "X-GitHub-Api-Version" = "2022-11-28"
        }
    
        $keyTitle = "$($Environment.ToLower())_01"
        
        Write-Debug "Reading all the deploy keys..."
        [array]$keys = Invoke-RestMethod -Method Get -Uri $repoKeysUrl -Headers $headers
        if ($keys) {
            Write-Debug "Check if key already exists..."
            [object]$existingKey = $keys | Where-Object { $_.title -eq $keyTitle }

            if ($existingKey -and $existingKey -ne '') {
                Write-Host "Deleting existing key '$keyTitle' having id '$($existingKey.id)'."
                Invoke-RestMethod -Method Delete -Uri ("$repoKeysUrl/{0}" -f $existingKey.id) -Headers $headers | Out-Null
            }
        }

        $body = @{
            "title" = $keyTitle
            "key" = $DeployKey
            "read_only" = $false
        } | ConvertTo-Json
        Write-Host "Adding new key '$keyTitle'..."
        Invoke-RestMethod -Method Post -Uri $repoKeysUrl -Body $body -Headers $headers | Out-Null
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
Write-Debug "${functionName}:AppId=$AppId"
Write-Debug "${functionName}:AppKey=$AppKey"
Write-Debug "${functionName}:Environment=$Environment"
Write-Debug "${functionName}:SSHPublicKeySecretName=$SSHPublicKeySecretName"
Write-Debug "${functionName}:KeyVaultName=$KeyVaultName"
Write-Debug "${functionName}:GitHubOrganisation=$GitHubOrganisation"
Write-Debug "${functionName}:GitHubRepository=$GitHubRepository"

try {
    Import-Module $PSHelperDirectory -Force

    $appInstallationUrl = "https://api.github.com/app/installations"
    $repoKeysUrl = "https://api.github.com/repos/$GitHubOrganisation/$GitHubRepository/keys"

    $jwt = Get-GithubJwt -AppId $AppId -AppKey $AppKey

    $installationToken = Get-InstallationToken -GitHubJwtToken $jwt

    $command = "az keyvault secret show --vault-name {0} --name {1}"
    $deployKey = Invoke-CommandLine -Command "$($command -f $KeyVaultName, $SSHPublicKeySecretName)" | ConvertFrom-Json
    Set-NewDeployKey -InstallationToken $installationToken -Environment $Environment -DeployKey $deployKey.value

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