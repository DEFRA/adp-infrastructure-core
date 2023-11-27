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

        New-MgGroup -BodyParameter $groupParameters
        if ($LASTEXITCODE -ne 0) {
            throw "unexpected exit code $LASTEXITCODE"
        }  
        Write-Host "AD Group '$($AADGroupObject.displayName)' created successfully."      
    }

    end {
        Write-Debug "${functionName}:Exited"
    }    
}

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

        Update-MgGroup -GroupId $GroupId -BodyParameter $groupParameters
        if ($LASTEXITCODE -ne 0) {
            throw "unexpected exit code $LASTEXITCODE"
        }   
        Write-Host "AD Group '$($AADGroupObject.displayName)' updated successfully."
    }

    end {
        Write-Debug "${functionName}:Exited"
    }    
}


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
            $user = Invoke-CommandLine -Command "Get-MgUser -Filter `"Mail eq '$_'`" -Property `"id,mail`""
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
            $serviceprincipal = Invoke-CommandLine -Command "Get-MgServicePrincipal -Filter `"DisplayName eq '$_'`" -Property `"id`""
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
            $group = Invoke-CommandLine -Command "Get-MgGroup -Filter `"DisplayName eq '$($_)'`" -Property `"id`""
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