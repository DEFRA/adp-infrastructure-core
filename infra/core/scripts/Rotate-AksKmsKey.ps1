[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $ServicePrincipalObjectId,
    [Parameter(Mandatory)]
    [string] $AzureSubscriptionId,
    [Parameter(Mandatory)]
    [string] $ResourceGroup,
    [Parameter(Mandatory)]
    [string] $ClusterName,
    [Parameter(Mandatory)]
    [string]$KeyVaultName,
    [Parameter()]
    [string]$WorkingDirectory = $PWD
)

function Update-SecretsRetry {
    param(
        [Parameter(Mandatory)]
        [string]$Namespace,
        [Parameter(Mandatory = $false)]
        [int]$MaxAttempts = 10
    )
    
    begin {
        [string]$functionName = $MyInvocation.MyCommand
        Write-Debug "${functionName}:Entered"
        Write-Debug "${functionName}:Namespace=$Namespace"
        Write-Debug "${functionName}:MaxAttempts=$MaxAttempts"
    }

    process {
        $attempts = 1    
        $ErrorActionPreferenceToRestore = $ErrorActionPreference
        $ErrorActionPreference = "Stop"
        
        do {
            try {
                $encryptSecrets = $(kubectl get secrets -n $Namespace -o json | kubectl replace -f -) 2>&1
                $encryptSecrets # For visibility that all secrets have been replaced to use encryption key
                $encryptSecretErrors = $encryptSecrets | Select-String Error
                if ($NULL -ne $encryptSecretErrors) {
                    throw
                }
                break;
            }
            catch [Exception] {
                Write-Host $_.Exception.Message
            }
           
            $attempts++
            if ($attempts -le $MaxAttempts) {
                $retryDelaySeconds = [math]::Pow(2, $attempts)
                $retryDelaySeconds = $retryDelaySeconds - 1 
                Write-Host("Action failed. Waiting " + $retryDelaySeconds + " seconds before attempt " + $attempts + " of " + $MaxAttempts + ".")
                Start-Sleep -Milliseconds $retryDelaySeconds            
            }
            else {
                $ErrorActionPreference = $ErrorActionPreferenceToRestore
                Write-Error $_.Exception.Message
            }
        } while ($attempts -le $MaxAttempts)
    
        $ErrorActionPreference = $ErrorActionPreferenceToRestore
    }
    
    end {
        Write-Debug "${functionName}:Exited"
    }
}

function Update-Secrets {
    
    begin {
        [string]$functionName = $MyInvocation.MyCommand
        Write-Debug "${functionName}:Entered"
    }

    process {
        $namespaces = kubectl get ns --no-headers -o custom-columns=":metadata.name"
        foreach ($namespace in $namespaces) {
            Write-Host "Updating Secrets in namespace: $nameSpace"
            Update-SecretsRetry -Namespace $namespace
            Write-Host "Successfully updated Secrets in namespace: $nameSpace"
        }
    }
    
    end {
        Write-Debug "${functionName}:Exited"
    }
}

function Set-NewKmsKey {
    param(
        [Parameter(Mandatory)]
        [string]$KeyVaultName,
        [Parameter(Mandatory)]
        [string]$ClusterName,
        [Parameter(Mandatory)]
        [string]$ResourceGroup
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand
        Write-Debug "${functionName}:Entered"
        Write-Debug "${functionName}:KeyVaultName=$KeyVaultName"
        Write-Debug "${functionName}:ClusterName=$ClusterName"
        Write-Debug "${functionName}:ResourceGroup=$ResourceGroup"
    }

    process {
        $currentDateTime = Get-Date -Format "yyyyMMddHHmmss"
        $keyName = "aksKmsKey-$currentDateTime"

        Write-Host "Add new key '$keyName' to KeyVault '$KeyVaultName'"
        #$keyId = az keyvault key create --name $keyName --vault-name $KeyVaultName --query 'key.kid' -o tsv
        $keyId = Invoke-CommandLine -Command "az keyvault key create --name $keyName --vault-name $KeyVaultName --query 'key.kid' -o tsv"
        Write-Host "Added new key '$keyName' to KeyVault '$KeyVaultName'"

        Write-Host "Getting keyVault resourceId for KeyVault '$KeyVaultName'"
        #$keyVaultResourceId = az keyvault show --name $KeyVaultName --query id -o tsv
        $keyVaultResourceId = Invoke-CommandLine -Command "az keyvault show --name $KeyVaultName --query id -o tsv"
        Write-Host "Finished getting keyVault resourceId for KeyVault '$KeyVaultName'"

        Write-Host "Rotate Key on cluster '$ClusterName' with new Key '$keyId'"
        Invoke-CommandLine -Command "az aks update --name $ClusterName --resource-group $ResourceGroup --enable-azure-keyvault-kms --azure-keyvault-kms-key-id $keyId --azure-keyvault-kms-key-vault-network-access 'Private' --azure-keyvault-kms-key-vault-resource-id $keyVaultResourceId"
        Write-Host "Rotated Key on cluster '$ClusterName' with new Key '$keyId'"
    }
    
    end {
        Write-Debug "${functionName}:Exited"
    }
}

# $AzureSubscriptionId = '55f3b8c6-6800-41c7-a40d-2adb5e4e1bd1'
# $ResourceGroup = 'SNDADPINFRG1402'
# $ClusterName = 'SNDADPINFAK1401-Test'
# $KeyVaultName = 'SNDADPINFVT1402'
# $ServicePrincipalObjectId = 'cbd7efdb-6513-46cc-9324-02ec477fc9da'

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
Write-Debug "${functionName}:ServicePrincipalObjectId=$ServicePrincipalObjectId"
Write-Debug "${functionName}:AzureSubscriptionId=$AzureSubscriptionId"
Write-Debug "${functionName}:WorkingDirectory=$WorkingDirectory"

try {
    [System.IO.DirectoryInfo]$moduleDir = Join-Path -Path $WorkingDirectory -ChildPath "scripts/modules/ps-helpers"
    Write-Debug "${functionName}:moduleDir.FullName=$($moduleDir.FullName)"
    Import-Module $moduleDir.FullName -Force

    $scope = "/subscriptions/$AzureSubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.ContainerService/managedClusters/$ClusterName"
    $role = "Azure Kubernetes Service RBAC Writer"

    Write-Host "Assigning role '$role' to '$ServicePrincipalObjectId' and deleting lock on cluster '$ClusterName'"
    Invoke-CommandLine -Command "az lock delete --name $ClusterName-CanNotDelete-lock --resource-group $ResourceGroup --resource $ClusterName --resource-type Microsoft.ContainerService/managedClusters" -NoOutput
    Invoke-CommandLine -Command "az role assignment create --assignee $ServicePrincipalObjectId --role '$role' --scope $scope" -NoOutput
    Write-Host "Assigned role '$role' to '$ServicePrincipalObjectId' deleted lock on cluster '$ClusterName'"

    Write-Host "Installing kubelogin"
    Invoke-CommandLine -Command "sudo az aks install-cli" -NoOutput
    Write-Host "Installed kubelogin"

    Write-Host "Download Cluster Credentials"
    Invoke-CommandLine -Command "az aks get-credentials --resource-group $ResourceGroup --name $ClusterName" -NoOutput
    Write-Host "Downloaded Cluster Credentials"

    Write-Host "Login using kubelogin plugin for authentication"
    Invoke-CommandLine -Command "kubelogin convert-kubeconfig -l azurecli" -NoOutput
    Write-Host "Logged in using kubelogin plugin for authentication"

    Write-Host "Update all secrets prior to Key rotation"
    Update-Secrets
    Write-Host "Updated updated all secrets prior to Key rotation"

    Write-Host "Rotate KMS Key"
    Set-NewKmsKey -KeyVaultName $KeyVaultName -ClusterName $ClusterName -ResourceGroup $ResourceGroup
    Write-Host "Rotated KMS Key"

    Write-Host "Update all secrets to use new Key after rotation"
    Update-Secrets
    Write-Host "Updated all secrets to use new Key after rotation"

    Write-Host "Delete role '$role' from '$ServicePrincipalObjectId' and add lock on cluster '$ClusterName'"
    Invoke-CommandLine -Command "az role assignment delete --assignee $ServicePrincipalObjectId --role '$role' --scope $scope" -NoOutput
    Invoke-CommandLine -Command "az lock create --name $ClusterName-CanNotDelete-lock --resource-group $ResourceGroup --resource $ClusterName --resource-type Microsoft.ContainerService/managedClusters --lock-type CanNotDelete" -NoOutput
    Write-Host "Deleted role '$role' from '$ServicePrincipalObjectId' added lock on cluster '$ClusterName'"
    
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