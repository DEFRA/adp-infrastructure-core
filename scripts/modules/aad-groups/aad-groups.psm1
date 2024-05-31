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

        Update-GroupOwners -GroupId $GroupId -AADGroupOwners $AADGroupObject.Owners

        Update-GroupMembers -GroupId $GroupId -AADGroupMembers $AADGroupObject.Members

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

         #Add the account as default owner which creates the group.
         if ((Get-AzContext).Account.Type -eq "ServicePrincipal") {
            [string]$accountid= (Get-AzContext).Account.Id
            Write-Host "accountid = '$accountid'"
            [string]$currentContextServicePrincipalID = (Get-MgServicePrincipal -Filter "AppId eq '$accountid'").Id
            Write-Host "currentContextServicePrincipalID = '$currentContextServicePrincipalID'"
            if($currentContextServicePrincipalID){
                $groupOwners.Add("https://graph.microsoft.com/v1.0/servicePrincipals/$($currentContextServicePrincipalID)")
                Write-Host "Default Owner set to Serviceprincipal ID = '$currentContextServicePrincipalID'"
            }
            else {
                Write-Host "##vso[task.logissue type=error]Default owner does not exit."
                exit 1
            }
        }

        if ($AADGroupOwners) {

            if ($AADGroupOwners.users) {
                $usersResult = Build-Users -AADUsers $AADGroupOwners.users
                $usersResult.foreach({$groupOwners.Add($_)})
            } 

            if ($AADGroupOwners.serviceprincipals) {
                $servicePrincipalsResult = Build-ServicePrincipals -Serviceprincipals $AADGroupOwners.serviceprincipals
                $servicePrincipalsResult.ForEach({
                    if ($groupOwners -notcontains $_) {
                        $groupOwners.Add($_)
                    }
                })    
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
            Write-Host "Getting User ID for user email '$_'"
            $user = Get-MgUser -Filter "Mail eq '$_' or UserPrincipalName eq '$_'" -Property "id,mail,UserPrincipalName" -ErrorAction Stop
            if ($user) {
                $users.Add("https://graph.microsoft.com/v1.0/users/$($user.id)")
            }
            else {
                Write-Host "##vso[task.logissue type=error]User with UserEmail $($_) does not exist."
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
Builds Array of Serviceprincipals. It uses 'Serviceprincipals Name' to find Serviceprincipal object ID and build "https://graph.microsoft.com/v1.0/servicePrincipals/{servicePrincipalObjectID}" strings.
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
            Write-Host "Getting Serviceprincipal ID for Serviceprincipal name '$_'"
            $serviceprincipal = Get-MgServicePrincipal -Filter "DisplayName eq '$_'" -Property "id"
            if ($serviceprincipal) {
                $servicePrincipalList.Add("https://graph.microsoft.com/v1.0/servicePrincipals/$($serviceprincipal.id)")
            }
            else {
                Write-Host "##vso[task.logissue type=error]Serviceprincipal $($_) does not exist."
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
            Write-Host "Getting AD Group ID for group name '$_'"
            $group = Get-MgGroup -Filter "DisplayName eq '$_'" -Property "id"
            if ($group) {
                $groups.Add("https://graph.microsoft.com/v1.0/groups/$($group.id)")
            }
            else {
                Write-Host "##vso[task.logissue type=error]Group $($_) does not exist."
            }
        }  
        return $groups

        end {
            Write-Debug "${functionName}:Exited"
        }    
    }
}


<#
.SYNOPSIS
Add Members to the existing group

.DESCRIPTION
Add Members to the existing group if it does not exist. Members can be type of 'User', 'Group' or 'ServicePrincipals'.

.PARAMETER AADGroupMembers
AAD Group Members Object (users, groups)

.PARAMETER GroupId
AAD Group Object Id

.EXAMPLE
Update-GroupMembers -AADGroupMembers <AADGroupMembers> -GroupId <GroupId>
#> 
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
                $usersResult = Find-NewUsersToAdd -GroupId $GroupId -ExistingGroupMembersOrOwners $existingGroupMembers -AADUsers $AADGroupMembers.users
                $usersResult | ForEach-Object {
                    New-MgGroupMember -GroupId $GroupId -DirectoryObjectId $_ -ErrorAction Stop
                    Write-Host "User '$($_)' Added as a member of the Group."
                }
            } 

            if ($AADGroupMembers.groups) {
                $aadGroupsResult = Find-NewGroupsToAdd -GroupId $GroupId -ExistingGroupMembersOrOwners $existingGroupMembers -AADGroups $AADGroupMembers.groups
                $aadGroupsResult | ForEach-Object {
                    New-MgGroupMember -GroupId $GroupId -DirectoryObjectId $_ -ErrorAction Stop
                    Write-Host "Group '$($_)' Added as a member of the Group."
                }
            } 

            if ($AADGroupMembers.serviceprincipals) {
                $spResult = Find-NewServicePrincipalsToAdd -GroupId $GroupId -ExistingGroupMembersOrOwners $existingGroupMembers -ServicePrincipals $AADGroupMembers.serviceprincipals
                $spResult | ForEach-Object {
                    New-MgGroupMember -GroupId $GroupId -DirectoryObjectId $_ -ErrorAction SilentlyContinue
                    Write-Host "ServicePrincipal '$($_)' Added as a member of the Group."
                }
            } 
        }    
    }

    end {
        Write-Debug "${functionName}:Exited"
    }    
}


<#
.SYNOPSIS
Add Owners to the existing group

.DESCRIPTION
Add Owners to the existing group if it does not exist. Owners can be type of 'User'.
Currently, service principals are not listed as group owners due to the staged rollout of service principals to the Microsoft Graph v1.0 endpoint.
Hence 'Service principals' is not included as a part of this module and also for update operation there is no use case to include 'service principal' as owner 
https://learn.microsoft.com/en-us/graph/api/group-list-owners?view=graph-rest-1.0&tabs=http

.PARAMETER AADGroupOwners
Mandatory. AAD Group Owners Object (which can be type of users, groups)

.PARAMETER GroupId
AAD Group Object Ids

.EXAMPLE
Update-GroupOwners -AADGroupOwners <AADGroupMembers> -GroupId <GroupId>
#> 
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

            [Object[]]$existingGroupOwners = Get-MgGroupOwner -GroupId $GroupId -Property "id" -All

            if ($AADGroupOwners.users) {
                $usersResult = Find-NewUsersToAdd -GroupId $GroupId -ExistingGroupMembersOrOwners $existingGroupOwners -AADUsers $AADGroupOwners.users
                $usersResult | ForEach-Object {
                    New-MgGroupOwner -GroupId $GroupId -DirectoryObjectId $_ -ErrorAction Stop
                    Write-Host "User '$($_)' Added as a owner of the Group."
                }
            } 

            if ($AADGroupOwners.serviceprincipals) {
                $spResult = Find-NewServicePrincipalsToAdd -GroupId $GroupId -ExistingGroupMembersOrOwners $existingGroupOwners -ServicePrincipals $AADGroupOwners.serviceprincipals
                $spResult | ForEach-Object {
                    New-MgGroupOwner -GroupId $GroupId -DirectoryObjectId $_ -ErrorAction SilentlyContinue
                    Write-Host "ServicePrincipal '$($_)' Added as a owner of the Group."
                }
            } 
        }    
    }

    end {
        Write-Debug "${functionName}:Exited"
    }    
}

<#
.SYNOPSIS
Build list of new Users to add to the existing group

.DESCRIPTION
Build list of new Users to add to the existing group either as owner or member.
It takes users emails array as input, checks if users is already a member/owner of the group and return only list 
of users which are not already a member/owner of the group

.PARAMETER GroupId
AAD Group Object Ids

.PARAMETER ExistingGroupMembersOrOwners
List of Existing Group Members or Owners (Users or groups)

.PARAMETER AADUsers
Mandatory. AAD Users Object

.EXAMPLE
Find-NewUsersToAdd -GroupId <GroupId> -ExistingGroupMembersOrOwners <ExistingGroupMembersOrOwners> -AADUsers <AADUsers>
#> 
Function Find-NewUsersToAdd() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]$GroupId,
        [Object[]]$ExistingGroupMembersOrOwners,
        [ValidateNotNullOrEmpty()]
        [Object[]]$AADUsers
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand    
        Write-Debug "${functionName}:Entered"   
        Write-Debug "${functionName}:GroupId=$($GroupId)" 
    }

    process {    
        Write-Debug "${functionName}:ExistingGroupMembersOrOwners=$($ExistingGroupMembersOrOwners | ConvertTo-Json -Depth 10)"
        Write-Debug "${functionName}:AADUsers=$($AADUsers | ConvertTo-Json -Depth 10)"
        
        $users = [System.Collections.Generic.List[string]]@()
        $AADUsers | ForEach-Object {
            Write-Host "Getting User ID for user email '$_'"
            $user = Get-MgUser -Filter "Mail eq '$_' or UserPrincipalName eq '$_'" -Property "id,mail,UserPrincipalName" -ErrorAction Stop
            if ($user) {
                if($ExistingGroupMembersOrOwners.Id -notcontains $user.id){
                    $users.Add($user.id)
                }
                else{
                    Write-Host "User with UserEmail '$($_)' is already a member/owner of the Group."
                }
            }
            else {
                Write-Host "##vso[task.logissue type=error]User with UserEmail '$($_)' does not exist."
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
Build list of new groups to add to the existing group

.DESCRIPTION
Build list of new Groups to add to the existing group either as owner or member.
It takes group name array as input, checks if group is already a member/owner of the group and return only list 
of groups which are not already a member/owner of the group

.PARAMETER GroupId
AAD Group Object Ids

.PARAMETER ExistingGroupMembersOrOwners
List of Existing Group Members or Owners (Users or groups)

.PARAMETER AADGroups
Mandatory. AAD groups Object

.EXAMPLE
Find-NewGroupsToAdd -GroupId <GroupId> -ExistingGroupMembersOrOwners <ExistingGroupMembersOrOwners> -AADGroups <AADGroups>
#> 
Function Find-NewGroupsToAdd() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]$GroupId,
        [Object[]]$ExistingGroupMembersOrOwners,
        [ValidateNotNullOrEmpty()]
        [Object[]]$AADGroups
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand    
        Write-Debug "${functionName}:Entered"   
        Write-Debug "${functionName}:GroupId=$($GroupId)" 
    }

    process {    
        Write-Debug "${functionName}:ExistingGroupMembersOrOwners=$($ExistingGroupMembersOrOwners | ConvertTo-Json -Depth 10)"
        Write-Debug "${functionName}:AADGroups=$($AADGroups | ConvertTo-Json -Depth 10)"
        
        $groups = [System.Collections.Generic.List[string]]@()
        $AADGroups | ForEach-Object {
            Write-Host "Getting AD Group ID for group name '$_'"
            $group = Get-MgGroup -Filter "DisplayName eq '$_'" -Property "id"
            if ($group) {
                if($ExistingGroupMembersOrOwners.Id -notcontains $group.id){
                    $groups.Add($group.id)
                }
                else{
                    Write-Host "Group '$($_)' is already a member/owner of the Group."
                }
            }
            else {
                Write-Host "##vso[task.logissue type=error]Group '$($_)' does not exist."
            }
        }  
        return $groups
        
        end {
            Write-Debug "${functionName}:Exited"
        }    
    }
}

<#
.SYNOPSIS
Build list of new service principals to add to the existing group

.DESCRIPTION
Build list of new service principals to add to the existing group either as owner or member.
It takes group name array as input, checks if service principal is already a member/owner of the group and return only list 
of service principals which are not already a member/owner of the group

.PARAMETER GroupId
AAD Group Object Ids

.PARAMETER ExistingGroupMembersOrOwners
List of Existing Group Members or Owners (Users or groups)

.PARAMETER ServicePrincipals
Mandatory. ServicePrincipals Object

.EXAMPLE
Find-NewServicePrincipalsToAdd -GroupId <GroupId> -ExistingGroupMembersOrOwners <ExistingGroupMembersOrOwners> ServicePrincipals <ServicePrincipals>
#> 
Function Find-NewServicePrincipalsToAdd() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]$GroupId,
        [Object[]]$ExistingGroupMembersOrOwners,
        [ValidateNotNullOrEmpty()]
        [Object[]]$ServicePrincipals
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand    
        Write-Debug "${functionName}:Entered"   
        Write-Debug "${functionName}:GroupId=$($GroupId)" 
    }

    process {    
        Write-Debug "${functionName}:ExistingGroupMembersOrOwners=$($ExistingGroupMembersOrOwners | ConvertTo-Json -Depth 10)"
        Write-Debug "${functionName}:ServicePrincipals=$($ServicePrincipals | ConvertTo-Json -Depth 10)"
        
        $spIds = [System.Collections.Generic.List[string]]@()
        $ServicePrincipals | ForEach-Object {
            Write-Host "Getting ServicePrincipal ID for Serviceprincipal name '$_'"
            $sp = Get-MgServicePrincipal -Filter "DisplayName eq '$_'" -Property "id"
            if ($sp) {
                if($ExistingGroupMembersOrOwners.Id -notcontains $sp.id){
                    $spIds.Add($sp.id)
                }
                else{
                    Write-Host "ServicePrincipal '$($_)' is already a member/owner of the Group."
                }
            }
            else {
                Write-Host "##vso[task.logissue type=error]ServicePrincipal '$($_)' does not exist."
            }
        }  
        return $spIds
        
        end {
            Write-Debug "${functionName}:Exited"
        }    
    }
}