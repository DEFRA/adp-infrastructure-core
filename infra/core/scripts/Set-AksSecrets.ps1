[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $ServicePrincipalId,
    [Parameter(Mandatory)]
    [string] $ServicePrincipalKey,
    [Parameter(Mandatory)]
    [string] $ServicePrincipalObjectId,
    [Parameter(Mandatory)]
    [string] $AzureSubscriptionId,
    [Parameter(Mandatory)]
    [string] $TenantId,
    [Parameter(Mandatory)]
    [string] $ResourceGroup,
    [Parameter(Mandatory)]
    [string] $ClusterName,
    [Parameter(Mandatory)]
    [string] $RotateKmsKey,
    [Parameter()]
    [string]$WorkingDirectory = $PWD
)

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
Write-Debug "${functionName}:ServicePrincipalId=$ServicePrincipalId"
Write-Debug "${functionName}:ServicePrincipalObjectId=$ServicePrincipalObjectId"
Write-Debug "${functionName}:AzureSubscriptionId=$AzureSubscriptionId"
Write-Debug "${functionName}:TenantId=$TenantId"
Write-Debug "${functionName}:RotateKmsKey=$rotateKmsKey"
Write-Debug "${functionName}:WorkingDirectory=$WorkingDirectory"

try {
    [System.IO.DirectoryInfo]$moduleDir = Join-Path -Path $WorkingDirectory -ChildPath "scripts/modules/ps-helpers"
    Write-Debug "${functionName}:moduleDir.FullName=$($moduleDir.FullName)"
    Import-Module $moduleDir.FullName -Force

    if ($RotateKmsKey -eq 'true') {
        Write-Host "Connecting to Azure..."
        Invoke-CommandLine -Command "az login --service-principal --tenant $TenantId --username $ServicePrincipalId --password $ServicePrincipalKey" -NoOutput
        Invoke-CommandLine -Command "az account set --name $AzureSubscriptionId" -NoOutput
        Write-Host "Connected to Azure and set context to '$AzureSubscriptionId'"

        $scope = "/subscriptions/$AzureSubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.ContainerService/managedClusters/$ClusterName"
        $role = "Azure Kubernetes Service RBAC Writer"
        # $assignee = "cbd7efdb-6513-46cc-9324-02ec477fc9da"
        Write-Host "Assigning role '$role' to '$ServicePrincipalObjectId' on cluster '$ClusterName'"
        Invoke-CommandLine -Command "az role assignment create --assignee $ServicePrincipalObjectId --role '$role' --scope $scope"
        Write-Host "Assigned role '$role' to '$ServicePrincipalObjectId' on cluster '$ClusterName'"

        Write-Host "Installing kubelogin"
        Invoke-CommandLine -Command "sudo az aks install-cli"
        Write-Host "Installed kubelogin"

        Write-Host "Download Cluster Credentials"
        Invoke-CommandLine -Command "az aks get-credentials --resource-group $ResourceGroup --name $ClusterName"
        Write-Host "Downloaded Cluster Credentials"

        Write-Host "Login using kubelogin plugin for authentication"
        Invoke-CommandLine -Command "kubelogin convert-kubeconfig -l azurecli"
        Write-Host "Logged in using kubelogin plugin for authentication"

        Write-Host "Encrypt all secrets with KMS Key by updating all secrets"
        Invoke-CommandLine -Command "kubectl get secrets --all-namespaces -o json | kubectl replace -f -"
        Write-Host "Encrypted all secrets with KMS Key by updating all secrets"

        # Write-Host "Deleteing role '$role' from '$assignee' on cluster '$ClusterName'"
        # Invoke-CommandLine -Command "az role assignment delete --assignee $assignee --role '$role' --scope $scope"
        # Write-Host "Deleted role '$role' from '$assignee' on cluster '$ClusterName'"
    }
    
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



if ($rotateKmsKey) {

    # Install kubelogin
    sudo az aks install-cli

    # az aks get-credentials --resource-group 'SNDADPINFRG1402' --name 'SNDADPINFAK1401'
    az aks get-credentials --resource-group 'asofluxpoc' --name 'asopocaks2'

    kubelogin convert-kubeconfig -l azurecli

    kubectl get secrets --all-namespaces -o json | kubectl replace -f -

}