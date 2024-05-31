<#
.SYNOPSIS
Create or Update an Azure AD security Group.

.DESCRIPTION
Create or Update an Azure AD security Group properties, members and owners.

.PARAMETER AADGroupsJsonManifestPath
Mandatory. AAD Groups configuration file.

.PARAMETER WorkingDirectory
Optional. Working directory. Default is $PWD.

.EXAMPLE
.\Create-AADGroups.ps1 AADGroupsJsonManifestPath <AAD Groups config json path>
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory)] 
    [string]$AADGroupsJsonManifestPath,
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
Write-Debug "${functionName}:AADGroupsJsonManifestPath=$AADGroupsJsonManifestPath"
Write-Debug "${functionName}:WorkingDirectory=$WorkingDirectory"

try {    
    [System.IO.DirectoryInfo]$adGroupsModuleDir = Join-Path -Path $WorkingDirectory -ChildPath "scripts/modules/aad-groups"
    Write-Debug "${functionName}:moduleDir.FullName=$($adGroupsModuleDir.FullName)"
    Import-Module $adGroupsModuleDir.FullName -Force
    ## Authenticate using Graph Powershell
    if (-not (Get-Module -ListAvailable -Name 'Microsoft.Graph')) {
        Write-Host "Microsoft.Graph Module does not exists. Installing now.."
        Install-Module Microsoft.Graph -Force
        Write-Host "Microsoft.Graph Installed Successfully."
    } 
    $graphApiToken = (Get-AzAccessToken -Resource https://graph.microsoft.com).Token 

    $targetParameter = (Get-Command Connect-MgGraph).Parameters['AccessToken']
    if ($targetParameter.ParameterType -eq [securestring]){
    Connect-MgGraph -AccessToken ($graphApiToken | ConvertTo-SecureString -AsPlainText -Force)
    }
    else {
    Connect-MgGraph -AccessToken $graphApiToken
    }
    Write-Host "======================================================"


    [PSCustomObject]$aadGroups = Get-Content -Raw -Path $AADGroupsJsonManifestPath | ConvertFrom-Json

    Write-Debug "${functionName}:aadGroups=$($aadGroups | ConvertTo-Json -Depth 10)"

    #Setup User AD groups
    if (($aadGroups.psobject.properties.match('userADGroups').Count -gt 0) -and $aadGroups.userADGroups) {
        foreach ($userAADGroup in $aadGroups.userADGroups) {
            $result = Get-MgGroup -Filter "DisplayName eq '$($userAADGroup.displayName)'"
        
            if ($result) {
                Write-Host "User AD Group '$($userAADGroup.displayName)' already exist. Group Id: $($result.Id)"
                Update-ADGroup -AADGroupObject $userAADGroup -GroupId $result.Id
            }
            else {
                Write-Host "User AD Group '$($userAADGroup.displayName)' does not exist."
                New-ADGroup -AADGroupObject $userAADGroup
            }
        }
    }
    else {
        Write-Host "No 'userADGroups' defined in group manifest file. Skipped"
    }

    #Setup Access AD groups
    if (($aadGroups.psobject.properties.match('accessADGroups').Count -gt 0) -and $aadGroups.accessADGroups) {
        foreach ($accessAADGroup in $aadGroups.accessADGroups) {
            $result = Get-MgGroup -Filter "DisplayName eq '$($accessAADGroup.displayName)'"
        
            if ($result) {
                Write-Host "Access AD Group '$($accessAADGroup.displayName)' already exist. Group Id: $result.Id"
                Update-ADGroup -AADGroupObject $accessAADGroup -GroupId $result.Id
            }
            else {
                Write-Host "Access AD Group '$($accessAADGroup.displayName)' does not exist."
                New-ADGroup -AADGroupObject $accessAADGroup
            }
        }
    }
    else {
        Write-Host "No 'accessADGroups' defined in group manifest file. Skipped"
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