<#
.SYNOPSIS
Create a New role assignment.

.DESCRIPTION
Create a New role assignment if it does not exist.

.PARAMETER Scope
Mandatory. The Scope of the role assignment. In the format of relative URI, For e.g subsciption scope =  "/subscriptions/{subscriptionID}"

.PARAMETER ObjectId
Mandatory. Azure AD Objectid of the user, group or service principal.

.PARAMETER RoleDefinitionName
Mandatory. Name of the RBAC role that needs to be assigned to the principal i.e. Contributor, User Access Administrator

.EXAMPLE
New-RoleAssignment -Scope $subscriptionScope -ObjectId $servicePrincipalObjectID -RoleDefinitionName "Contributor"
#>
Function New-RoleAssignment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True)]$Scope,
        [Parameter(Mandatory = $True)]$ObjectId,
        [Parameter(Mandatory = $True)]$RoleDefinitionName
    )
    $isRoleAssignmentExist = (Get-AzRoleAssignment -Scope $Scope -RoleDefinitionName $RoleDefinitionName -ObjectId $ObjectId)

    if (-not $isRoleAssignmentExist) {
        Write-Host "Creating new Role Assignment : RoleDefinitionName = $RoleDefinitionName, Scope = $Scope, ObjectId = $ObjectId"
        New-AzRoleAssignment -Scope $subscriptionScope -RoleDefinitionName $RoleDefinitionName -ObjectId $ObjectId | Out-Null
    }
    else {
        Write-Host "Role Assignment already exist for : RoleDefinitionName = $RoleDefinitionName, Scope = $subscriptionScope, ObjectId = $ObjectId"
    }
}