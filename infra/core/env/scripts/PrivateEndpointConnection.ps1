<#
.SYNOPSIS
Check and approve the private endpoint connection request

.DESCRIPTION
Check and approve the private endpoint connection request

.PARAMETER OpenAiName
Mandatory. OpenAi Name

.PARAMETER ResourceGroupName
Mandatory. Resource Group Name.

.PARAMETER SearchServiceName
Mandatory. SearchService Name

.PARAMETER Command
Mandatory. Command to check if the private endpoint connection exists or approve the connection

.EXAMPLE
.\PrivateEndpointConnection.ps1 -OpenAiName <OpenAiName> -resourceGroupName <ResourceGroupName> -SearchServiceName <SearchServiceName> -Command <Command>
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory)] 
    [string]$OpenAiName,
    [Parameter(Mandatory)] 
    [string]$ResourceGroupName,
    [Parameter(Mandatory)] 
    [string]$SearchServiceName,
    [Parameter(Mandatory)] 
    [string]$Command    
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
Write-Debug "${functionName}:OpenAiName=$OpenAiName"
Write-Debug "${functionName}:ResourceGroupName=$ResourceGroupName"
Write-Debug "${functionName}:SearchServiceName=$SearchServiceName"
Write-Debug "${functionName}:Command=$Command"

try {

    $resourceProperties = Get-AzResource -ResourceGroupName $ResourceGroupName -Name $openAiName  -ExpandProperties
    $privateEndpointConnections = $resourceProperties.properties.privateEndpointConnections
    if ($Command -eq "Check") {
        $objList = $privateEndpointConnections | Where-Object -Property name -match $SearchServiceName 
        if ($objList) {
            Write-Host "Private Endpoint Connection exists"
            Write-Host "##vso[task.setvariable variable=privateLinkServiceConnectionExists;]$true"
        }
        else {
            Write-Host "##vso[task.setvariable variable=privateLinkServiceConnectionExists;]$false"
            Write-Host "Private Endpoint Connection does not exist"
        }
    }
    elseif ($Command -eq "Approve") {
        $objList = $privateEndpointConnections | Where-Object -Property name -match $SearchServiceName | Where-Object { $_.properties.privateLinkServiceConnectionState.status -eq 'Pending' }
        $objList | ForEach-Object { Approve-AzPrivateEndpointConnection -ResourceId $_.id }
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