<#
.SYNOPSIS
Create a new Azure AD Security Group.

.DESCRIPTION
Create a new Azure AD Security Group. Owners and members can be added optionally. 

.PARAMETER AADGroupObject
Mandatory. AAD Group Object (description, displayName, Owners, Members)

.EXAMPLE
New-ADGroup -AADGroupObject <AADGroupObject>
#> 
Function New-ADGroup() {
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
        
        Write-Host "Creating new group : $($AADGroupObject.displayName)"

        $groupParameters = @{
            description     = $AADGroupObject.description
            displayName     = $AADGroupObject.displayName
            mailEnabled     = $false
            securityEnabled = $true
            mailNickname    = $AADGroupObject.displayName
        }

        [object[]]$owners = Build-GroupOwners -AADGroupOwners $AADGroupObject.Owners
        if ($owners) {
            $groupParameters.Add("owners@odata.bind", $owners)
        }
        else {
            Write-Host "No owners defined for '$($AADGroupObject.displayName)' group."
        }

        [object[]]$members = Build-GroupMembers -AADGroupMembers $AADGroupObject.Members
        if ($members) {
            $groupParameters.Add("members@odata.bind", $members)
        }
        else {
            Write-Host "No members defined for '$($AADGroupObject.displayName)' group."
        }

        New-MgGroup -BodyParameter $groupParameters -ErrorAction Stop
        Write-Host "AD Group '$($AADGroupObject.displayName)' created successfully."      
    }

    end {
        Write-Debug "${functionName}:Exited"
    }    
}

<#
.SYNOPSIS
Update a Azure AD Security Group.

.DESCRIPTION
Update a Azure AD Security Group. This function currently supports to update only 'description' property.

.PARAMETER AADGroupObject
Mandatory. AAD Group Object (description, displayName, Owners, Members)

.EXAMPLE
Update-ADGroup -AADGroupObject <AADGroupObject>
#> 
Function Update-ADGroup() {
    [CmdletBinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline = $true)]
        [Object]$AADGroupObject,
        [Parameter(Mandatory)]
        [string]$GroupId
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand    
        Write-Debug "${functionName}:Entered"   
        Write-Debug "${functionName}:GroupId=$($GroupId)"  
    }

    process {    
        Write-Debug "${functionName}:AADGroupObject=$($AADGroupObject | ConvertTo-Json -Depth 10)"

        Write-Host "Updating group : $($AADGroupObject.displayName)"

        $groupParameters = @{
            description = $AADGroupObject.description
        }

        # Update-GroupOwners -GroupId $GroupId -AADGroupOwners $AADGroupObject.Owners

        # Update-GroupMembers -GroupId $GroupId -AADGroupMembers $AADGroupObject.Members

        [object[]]$owners = Build-GroupOwners -AADGroupOwners $AADGroupObject.Owners
        if ($owners) {
            $groupParameters.Add("owners@odata.bind", $owners)
        }
        else {
            Write-Host "No owners defined for '$($AADGroupObject.displayName)' group."
        }

        Update-MgGroup -GroupId $GroupId -BodyParameter $groupParameters -ErrorAction Stop

        Write-Host "AD Group '$($AADGroupObject.displayName)' updated successfully."
    }

    end {
        Write-Debug "${functionName}:Exited"
    }    
}

<#
.SYNOPSIS
Builds Array of Members.

.DESCRIPTION
Builds Array of Members which is used while creating new group. Members can be type of 'User', 'ServicePrincipal' or 'Group'.

.PARAMETER AADGroupMembers
Mandatory. AAD Group Members Object (users, serviceprincipals, groups)

.EXAMPLE
Build-GroupMembers -AADGroupMembers <AADGroupMembers>
#> 
Function Build-GroupMembers() {
    [CmdletBinding()]
    Param(
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
                $usersResult = Build-Users -AADUsers $AADGroupMembers.users
                $usersResult.foreach({$groupMembers.Add($_)})
            } 

            if ($AADGroupMembers.serviceprincipals) {
                $servicePrincipalsResult = Build-ServicePrincipals -Serviceprincipals $AADGroupMembers.serviceprincipals
                $servicePrincipalsResult.foreach({$groupMembers.Add($_)})
            } 

            if ($AADGroupMembers.groups) {
                $aadGroupsResult = Build-Groups -AADGroups $AADGroupMembers.groups
                $aadGroupsResult.foreach({$groupMembers.Add($_)})
            } 
        }    
        
        return $groupMembers
    }

    end {
        Write-Debug "${functionName}:Exited"
    }    
}

<#
.SYNOPSIS
Builds Array of Owners.

.DESCRIPTION
Builds Array of Owners which is used while creating new group. Owners can be type of 'User', 'ServicePrincipal'.

.PARAMETER AADGroupOwners
Mandatory. AAD Group Owners Object (users, serviceprincipals)

.EXAMPLE
Build-GroupOwners -AADGroupOwners <AADGroupOwners>
#> 
Function Build-GroupOwners() {
    [CmdletBinding()]
    Param(
        [Object]$AADGroupOwners
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand    
        Write-Debug "${functionName}:Entered"   
    }

    process {    
        Write-Debug "${functionName}:AADGroupOwners=$($AADGroupOwners | ConvertTo-Json -Depth 10)"
        
        $groupOwners = New-Object Collections.Generic.List[string]
        if ($AADGroupOwners) {

            if ($AADGroupOwners.users) {
                $usersResult = Build-Users -AADUsers $AADGroupOwners.users
                $usersResult.foreach({$groupOwners.Add($_)})
            } 

            if ($AADGroupOwners.serviceprincipals) {
                $servicePrincipalsResult = Build-ServicePrincipals -Serviceprincipals $AADGroupOwners.serviceprincipals
                $servicePrincipalsResult.foreach({$groupOwners.Add($_)})
            }
        }    
        
        return $groupOwners
    }

    end {
        Write-Debug "${functionName}:Exited"
    }    
}

<#
.SYNOPSIS
Builds Array of Users.

.DESCRIPTION
Builds Array of Users. It uses 'User Emails' to find user object ID and build "https://graph.microsoft.com/v1.0/users/{userID}" strings.
It is internal function used by 'Build-GroupOwners' and 'Build-GroupMembers'.

.PARAMETER AADUsers
Mandatory. AAD Users Object

.EXAMPLE
Build-Users -AADUsers <AADUsers>
#> 
Function Build-Users() {
    [CmdletBinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        [Object[]]$AADUsers
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand    
        Write-Debug "${functionName}:Entered"   
    }

    process {    
        Write-Debug "${functionName}:Users=$($AADUsers | ConvertTo-Json -Depth 10)"
        
        $users = [System.Collections.Generic.List[string]]@()
        $AADUsers | ForEach-Object {
            Write-Debug "${functionName}:Getting User ID for user email '$_'"
            $user = Get-MgUser -Filter "Mail eq '$_' or UserPrincipalName eq '$_'" -Property "id,mail,UserPrincipalName" -ErrorAction Stop
            if ($user) {
                $users.Add("https://graph.microsoft.com/v1.0/users/$($user.id)")
            }
            else {
                Write-Error "User with UserEmail $($_) does not exist."
            }
        }
        return $users

        end {
            Write-Debug "${functionName}:Exited"
        }    
    }
}

<#
.SYNOPSIS
Builds Array of Serviceprincipals.

.DESCRIPTION
Builds Array of Users. It uses 'Serviceprincipals Name' to find Serviceprincipal object ID and build "https://graph.microsoft.com/v1.0/servicePrincipals/{servicePrincipalObjectID}" strings.
It is internal function used by 'Build-GroupOwners' and 'Build-GroupMembers'.

.PARAMETER AADUsers
Mandatory. Serviceprincipals Object

.EXAMPLE
Build-ServicePrincipals -Serviceprincipals <Serviceprincipals>
#> 
Function Build-ServicePrincipals() {
    [CmdletBinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        [Object[]]$Serviceprincipals
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand    
        Write-Debug "${functionName}:Entered"   
    }

    process {    
        Write-Debug "${functionName}:Serviceprincipals=$($Serviceprincipals | ConvertTo-Json -Depth 10)"
        
        $servicePrincipalList = [System.Collections.Generic.List[string]]@()
        $Serviceprincipals | ForEach-Object {
            Write-Debug "${functionName}:Getting Serviceprincipal ID for Serviceprincipal name '$_'"
            $serviceprincipal = Get-MgServicePrincipal -Filter "DisplayName eq '$_'" -Property "id"
            if ($serviceprincipal) {
                $servicePrincipalList.Add("https://graph.microsoft.com/v1.0/servicePrincipals/$($serviceprincipal.id)")
            }
            else {
                Write-Error "Serviceprincipal $($_) does not exist."
            }
        }  
        return $servicePrincipalList

        end {
            Write-Debug "${functionName}:Exited"
        }    
    }
}

<#
.SYNOPSIS
Builds Array of AADGroups.

.DESCRIPTION
Builds Array of Groups. It uses 'AADGroups Name' to find Group object ID and build "https://graph.microsoft.com/v1.0/groups/{groupId}" strings.
It is internal function used by 'Build-GroupMembers'.

.PARAMETER AADGroups
Mandatory. AADGroups Object

.EXAMPLE
Build-Groups -AADGroups <AADGroups>
#> 
Function Build-Groups() {
    [CmdletBinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        [Object[]]$AADGroups
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand    
        Write-Debug "${functionName}:Entered"   
    }

    process {    
        Write-Debug "${functionName}:AADGroups=$($AADGroups | ConvertTo-Json -Depth 10)"
        
        $groups = [System.Collections.Generic.List[string]]@()
        $AADGroups | ForEach-Object {
            Write-Debug "${functionName}:Getting AD Group ID for group name '$_'"
            $group = Get-MgGroup -Filter "DisplayName eq '$_'" -Property "id"
            if ($group) {
                $groups.Add("https://graph.microsoft.com/v1.0/groups/$($group.id)")
            }
            else {
                Write-Error "Group $($_) does not exist."
            }
        }  
        return $groups

        end {
            Write-Debug "${functionName}:Exited"
        }    
    }
}


Function Update-GroupMembers() {
    [CmdletBinding()]
    Param(        
        [Object]$AADGroupMembers,
        [Parameter(Mandatory)]
        [string]$GroupId
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand    
        Write-Debug "${functionName}:Entered"   
        Write-Debug "${functionName}:GroupId=$($GroupId)" 
    }

    process {    
        Write-Debug "${functionName}:AADGroupMembers=$($AADGroupMembers | ConvertTo-Json -Depth 10)"
        
        if ($AADGroupMembers) {

            [Object[]]$existingGroupMembers = Get-MgGroupMember -GroupId $GroupId -Property "id" -All

            if ($AADGroupMembers.users) {
                $usersResult = Find-NewUsersToAdd -GroupId $GroupId -ExistingGroupMembers $existingGroupMembers -AADUsers $AADGroupMembers.users
                $usersResult | ForEach-Object {
                    New-MgGroupMember -GroupId $GroupId -DirectoryObjectId $_
                    Write-Debug "User $($_) Added as a member of the Group."
                }
            } 

            if ($AADGroupMembers.groups) {
                $aadGroupsResult = Find-NewGroupsToAdd -GroupId $GroupId -ExistingGroupMembers $existingGroupMembers -AADGroups $AADGroupMembers.groups
                $aadGroupsResult | ForEach-Object {
                    New-MgGroupMember -GroupId $GroupId -DirectoryObjectId $_
                    Write-Debug "Group $($_) Added as a member of the Group."
                }
            } 
        }    
    }

    end {
        Write-Debug "${functionName}:Exited"
    }    
}

Function Update-GroupOwners() {
    [CmdletBinding()]
    Param(        
        [Object]$AADGroupOwners,
        [Parameter(Mandatory)]
        [string]$GroupId
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand    
        Write-Debug "${functionName}:Entered"   
        Write-Debug "${functionName}:GroupId=$($GroupId)" 
    }

    process {    
        Write-Debug "${functionName}:AADGroupOwners=$($AADGroupOwners | ConvertTo-Json -Depth 10)"
        
        if ($AADGroupOwners) {

            [Object[]]$existingGroupMembers = Get-MgGroupMember -GroupId $GroupId -Property "id" -All

            if ($AADGroupOwners.users) {
                $usersResult = Find-NewUsersToAdd -GroupId $GroupId -ExistingGroupMembers $existingGroupMembers -AADUsers $AADGroupOwners.users
                $usersResult | ForEach-Object {
                    New-MgGroupOwner -GroupId $GroupId -DirectoryObjectId $_
                    Write-Debug "User $($_) Added as a owner of the Group."
                }
            } 
        }    
    }

    end {
        Write-Debug "${functionName}:Exited"
    }    
}

Function Find-NewUsersToAdd() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]$GroupId,
        [Object[]]$ExistingGroupMembers,
        [ValidateNotNullOrEmpty()]
        [Object[]]$AADUsers
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand    
        Write-Debug "${functionName}:Entered"   
        Write-Debug "${functionName}:GroupId=$($GroupId)" 
    }

    process {    
        Write-Debug "${functionName}:ExistingGroupMembers=$($ExistingGroupMembers | ConvertTo-Json -Depth 10)"
        Write-Debug "${functionName}:Users=$($AADUsers | ConvertTo-Json -Depth 10)"
        
        $users = [System.Collections.Generic.List[string]]@()
        $AADUsers | ForEach-Object {
            Write-Debug "${functionName}:Getting User ID for user email '$_'"
            $user = Get-MgUser -Filter "Mail eq '$_' or UserPrincipalName eq '$_'" -Property "id,mail,UserPrincipalName" -ErrorAction Stop
            if ($user) {
                if($ExistingGroupMembers.Id -notcontains $user.id){
                    $users.Add($user.id)
                }
                else{
                    Write-Debug "User with UserEmail $($_) is already a member of the Group."
                }
            }
            else {
                Write-Error "User with UserEmail $($_) does not exist."
            }
        }
        return $users

        end {
            Write-Debug "${functionName}:Exited"
        }    
    }
}

Function Find-NewGroupsToAdd() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]$GroupId,
        [Object[]]$ExistingGroupMembers,
        [ValidateNotNullOrEmpty()]
        [Object[]]$AADGroups
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand    
        Write-Debug "${functionName}:Entered"   
        Write-Debug "${functionName}:GroupId=$($GroupId)" 
    }

    process {    
        Write-Debug "${functionName}:ExistingGroupMembers=$($ExistingGroupMembers | ConvertTo-Json -Depth 10)"
        Write-Debug "${functionName}:AADGroups=$($AADGroups | ConvertTo-Json -Depth 10)"
        
        $groups = [System.Collections.Generic.List[string]]@()
        $AADGroups | ForEach-Object {
            Write-Debug "${functionName}:Getting AD Group ID for group name '$_'"
            $group = Get-MgGroup -Filter "DisplayName eq '$_'" -Property "id"
            if ($group) {
                if($ExistingGroupMembers.Id -notcontains $group.id){
                    $groups.Add($group.id)
                }
                else{
                    Write-Debug "Group $($_) is already a member of the Group."
                }
            }
            else {
                Write-Error "Group $($_) does not exist."
            }
        }  
        return $groups
        
        end {
            Write-Debug "${functionName}:Exited"
        }    
    }
}