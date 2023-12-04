<#
.SYNOPSIS
Creates an Azure Role Assignment

.DESCRIPTION
Creates an Azure Role Assignment if does not exist.

.PARAMETER RoleAssignmentsJsonPath
Mandatory. Role Assignments configuration file.

.EXAMPLE
.\Set-RoleAssignments -RoleAssignmentsJsonPath <RoleAssignments config json path>
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory)] 
    [string]$RoleAssignmentsJsonPath
)

Function Set-RoleAssignment {
    [CmdletBinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline = $true)]
        [Object]$RoleAssignment
    )
    
    begin {
        [string]$functionName = $MyInvocation.MyCommand    
        Write-Debug "${functionName}:Entered"
    }

    process {    
        Write-Debug "${functionName}:RoleAssignment=$($RoleAssignment | ConvertTo-Json -Depth 10)"

        Write-Host "Fethcing Keyvault secret $($RoleAssignment.ObjectId.keyVault.secretKey) from KeyVaultName $($RoleAssignment.ObjectId.keyVault.name)"
        [string]$servicePrincipalObjectId = Get-AzKeyVaultSecret -VaultName $RoleAssignment.ObjectId.keyVault.name -Name $RoleAssignment.ObjectId.keyVault.secretKey -AsPlainText -ErrorAction Stop
        Write-Debug "${functionName}:$($RoleAssignment.ObjectId.keyVault.secretKey) = $($servicePrincipalObjectId)"
        
        if($servicePrincipalObjectId){
            New-RoleAssignment -Scope $RoleAssignment.Scope -ObjectId $servicePrincipalObjectId -RoleDefinitionName $RoleAssignment.RoleDefinitionName -RoleAssignmentDescription $RoleAssignment.RoleAssignmentDescription
        }
        else {
            Write-Error "Object Id not found. $($RoleAssignment.ObjectId.keyVault.secretKey) secret does not exist."
        }
    }

    end {
        Write-Debug "${functionName}:Exited"
    }    
}

Function New-RoleAssignment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True)]$Scope,
        [Parameter(Mandatory = $True)]$ObjectId,
        [Parameter(Mandatory = $True)]$RoleDefinitionName,
        [Parameter(Mandatory = $True)]$RoleAssignmentDescription
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand    
        Write-Debug "${functionName}:Entered"
        Write-Debug "${functionName}:Scope=$Scope"
        Write-Debug "${functionName}:ObjectId=$ObjectId"
        Write-Debug "${functionName}:RoleDefinitionName=$RoleDefinitionName"
        Write-Debug "${functionName}:RoleAssignmentDescription=$RoleAssignmentDescription"
    }

    process {    
        $isRoleAssignmentExist = (Get-AzRoleAssignment -Scope $Scope -RoleDefinitionName $RoleDefinitionName -ObjectId $ObjectId)
        Write-Debug "isRoleAssignmentExist=$isRoleAssignmentExist"
    
        if (-not $isRoleAssignmentExist) {
            Write-Host "Creating new Role Assignment : RoleDefinitionName = $RoleDefinitionName, Scope = $Scope, ObjectId = $ObjectId"
            # New-AzRoleAssignment -Scope $subscriptionScope -RoleDefinitionName $RoleDefinitionName -ObjectId $ObjectId | Out-Null
        }
        else {
            Write-Host "Role Assignment already exist for : RoleDefinitionName = $RoleDefinitionName, Scope = $Scope, ObjectId = $ObjectId"
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
Write-Debug "${functionName}:RoleAssignmentsJsonPath=$RoleAssignmentsJsonPath"

try {

    [PSCustomObject]$roleAssignments = Get-Content -Raw -Path $RoleAssignmentsJsonPath | ConvertFrom-Json

    $roleAssignments.azureRoleAssignments | Set-RoleAssignment

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