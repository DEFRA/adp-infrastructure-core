<#
.SYNOPSIS
Create or Update an Azure RM type service endpoint (ServiceConnection).

.DESCRIPTION
Create an Azure RM type service endpoint (ServiceConnection). It also verifies the service endpoint using endpointproxy.

.PARAMETER AADGroupsJsonManifestPath
Mandatory. Service connection configuration file.

.PARAMETER WorkingDirectory
Optional. Working directory. Default is $PWD.

.EXAMPLE
.\Initialize-ServiceEndpoint.ps1 AADGroupsJsonManifestPath <Service endpoint config json path>
#> 

[CmdletBinding()]
param(
    # [Parameter(Mandatory)] 
    [string]$AADGroupsJsonManifestPath = 'C:\ganesh\projects\defra\repo\github\adp-infrastructure\infra\bootstrap\config\aad-groups\platformAADGroups.defra.json',
    [Parameter()]
    [string]$WorkingDirectory = $PWD
)

Function New-MgGroup() {
    [CmdletBinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline = $true)]
        [Object]$AADGroupObject
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand    
        Write-Debug "${functionName}:Entered"   
    }

    process {    
        Write-Debug "${functionName}:AADGroupObject=$($AADGroupObject | ConvertTo-Json -Depth 10)"
        
         $members = Build-GroupMembers -AADGroupMembers $AADGroupObject.Members

        $param = @{
            description         = $AADGroupObject.description
            displayName         = $AADGroupObject.displayName
            mailEnabled         = $false
            securityEnabled     = $true
            mailNickname        = $AADGroupObject.displayName
        }

        if($members){
            $param | Add-Member -NotePropertyName "members@odata.bind" -NotePropertyValue $members
        }
        
        
    }

    end {
        Write-Debug "${functionName}:Exited"
    }    
}

Function Update-MgGroup() {
    [CmdletBinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline = $true)]
        [Object]$AADGroupObject
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand    
        Write-Debug "${functionName}:Entered"   
    }

    process {    
        Write-Debug "${functionName}:AADGroupObject=$($AADGroupObject | ConvertTo-Json -Depth 10)"
    }

    end {
        Write-Debug "${functionName}:Exited"
    }    
}


Function Build-GroupMembers() {
    [CmdletBinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        [Object]$AADGroupMembers
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand    
        Write-Debug "${functionName}:Entered"   
    }

    process {    
        Write-Debug "${functionName}:AADGroupMembers=$($AADGroupMembers | ConvertTo-Json -Depth 10)"
        
        $groupMembers = New-Object Collections.Generic.List[string]
        if ($AADGroupMembers) {
            if ($AADGroupMembers.users) {
                $AADGroupMembers.users | ForEach-Object {
                    Write-Debug "$_"
                    $user = Get-MgUser -Filter "Mail eq '$_'" -Property "id,mail" 
                    if ($user) {
                        $groupMembers.Add("https://graph.microsoft.com/v1.0/users/$($user.id)")
                    }
                    else {
                        Write-Error "Member with UserEmail $($_) does not exist."
                    }
                    
                }
            } 
        }    
        
        return $groupMembers
    }

    end {
        Write-Debug "${functionName}:Exited"
    }    
}

Set-Variable -Name DebugPreference -Value Continue -Scope global
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

    # [System.IO.DirectoryInfo]$moduleDir = Join-Path -Path $WorkingDirectory -ChildPath "scripts/modules/ado"
    # Write-Debug "${functionName}:moduleDir.FullName=$($moduleDir.FullName)"

    # Import-Module $moduleDir.FullName -Force

    # Authenticate : Connect to Graph using access token

    [PSCustomObject]$aadGroups = Get-Content -Raw -Path $AADGroupsJsonManifestPath | ConvertFrom-Json

    $functionInput = @{
        securityEnabled = $true
    }

    #Setup User AD groups
    if ($aadGroups.userADGroups) {
        foreach ($userAADGroup in $aadGroups.userADGroups) {

            $result = Get-MgGroup -Filter "DisplayName eq '$($userAADGroup.displayName)'" -ExpandProperty Members
            if ($result) {
                Write-Debug "User AD Group '$($userAADGroup.displayName)' already exist."
                Update-MgGroup -AADGroupObject $userAADGroup
            }
            else {
                Write-Debug "User AD Group '$($userAADGroup.displayName)' does not exist."
                New-MgGroup -AADGroupObject $userAADGroup
            }
        }

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