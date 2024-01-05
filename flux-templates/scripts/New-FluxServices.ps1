[CmdletBinding()]
param(
    [Parameter(Mandatory)] 
    [string]$TemplatesPath,
    [Parameter(Mandatory)]
    [string]$OnBoardingManifest,
    [Parameter(Mandatory)] 
    [string]$FluxServicesPath,
    [Parameter(Mandatory)]
    [string]$PSHelperDirectory
)

function ReplaceTokens {
    param(
        [Parameter(Mandatory)]
        [string]$TemplateFile,
        [Parameter(Mandatory)]
        [string]$DestinationFile
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand
        Write-Debug "${functionName}:Entered"
        Write-Debug "${functionName}:TemplateFile=$TemplateFile"
        Write-Debug "${functionName}:DestinationFile=$DestinationFile"
    }
    process {  
        Get-Content -Path $TemplateFile | ForEach-Object {
            $line = $_
        
            $lookupTable.GetEnumerator() | ForEach-Object {
                if ($line -match $_.Key) {
                    $line = $line -replace $_.Key, $_.Value
                }
            }
            $line
        } | Set-Content -Path $DestinationFile
    }

    end {
        Write-Debug "${functionName}:Exited"
    }
}

function New-Directory {
    param(
        [Parameter(Mandatory)]
        [string]$DirectoryPath
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand
        Write-Debug "${functionName}:Entered"
        Write-Debug "${functionName}:DirectoryPath=$DirectoryPath"
    }
    process {  
        if (-not (test-path $DirectoryPath) ) {
            Write-Host "$DirectoryPath doesn't exist, creating it"
            New-Item -Path $DirectoryPath -Type Directory
        }
        else {
            Write-Host "$DirectoryPath exists, no need to create it"
        }
    }

    end {
        Write-Debug "${functionName}:Exited"
    }
}

function New-FeatureBranch {
    param(
        [Parameter(Mandatory)]
        [string]$ProgrammeName
    )
    begin {
        [string]$functionName = $MyInvocation.MyCommand
        Write-Debug "${functionName}:Entered"
        Write-Debug "${functionName}:ProgrammeName=$ProgrammeName"
    }
    process {
        [string]$userEmail = "ado@noemail.com"
        [string]$userName = "Devops"

        [string]$gitUserEmailCommand = "git config user.email $userEmail"
        Write-Host $gitUserEmailCommand
        Invoke-CommandLine -Command $gitUserEmailCommand | Out-Null

        [string]$gitUserNameCommand = "git config user.name $userName"
        Write-Host $gitUserNameCommand
        Invoke-CommandLine -Command $gitUserNameCommand | Out-Null

        [string]$gitPullCommand = "git pull origin main"
        Write-Host $gitPullCommand
        Invoke-CommandLine -Command $gitPullCommand | Out-Null

        [string]$gitCheckoutCommand = "git checkout -b feature-$ProgrammeName-onboarding"
        Write-Host $gitCheckoutCommand
        Invoke-CommandLine -Command $gitCheckoutCommand | Out-Null

        [string]$gitStagingCommand = "git add -A"
        Write-Host $gitStagingCommand
        Invoke-CommandLine -Command $gitStagingCommand | Out-Null

        [string]$commitMessage = "Add Flux Services for $ProgrammeName"
        [string]$author = "ADO Devops <ado@noemail.com>"
        [string]$gitCommitCommand = "git commit -am '$commitMessage' --author='$author'"
        Write-Host $gitCommitCommand
        Invoke-CommandLine -Command $gitCommitCommand | Out-Null

        [string]$gitPushCommand = "git push -f --set-upstream origin feature-$ProgrammeName-onboarding"
        Write-Host $gitPushCommand
        Invoke-CommandLine -Command $gitPushCommand | Out-Null
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
Write-Debug "${functionName}:TemplatesPath=$TemplatesPath"
Write-Debug "${functionName}:OnBoardingManifest=$OnBoardingManifest"
Write-Debug "${functionName}:FluxServicesPath=$FluxServicesPath"
Write-Debug "${functionName}:PSHelperDirectory=$PSHelperDirectory"

try {
    Write-Host "Import module:PSHelperDirectory=$PSHelperDirectory"
    Import-Module $PSHelperDirectory -Force

    Write-Host "OnBoardingManifest: '$OnBoardingManifest'"
    [hashtable]$programmeDetails = $OnBoardingManifest | ConvertFrom-Json -AsHashtable

    [string]$programmeName = $programmeDetails.name
    [array]$teams = $programmeDetails.teams

    [hashtable]$lookupTable = @{
        '__PROGRAMME_NAME__' = $programmeName
        '__SERVICE_CODE__'   = 'INITIALIZE'
        '__TEAM_NAME__'      = 'INITIALIZE'
        '__SERVICE_NAME__'   = 'INITIALIZE'
        '__ENVIRONMENT__'    = 'INITIALIZE'
        '__ENV_INSTANCE__'   = 'INITIALIZE'
        '__DEPENDS_ON__'     = 'INITIALIZE'
        '__POSTGRES_DB__'    = 'INITIALIZE'
    }

    [string]$programmePath = "$FluxServicesPath/$programmeName"
    [string]$environmentsPath = "$FluxServicesPath/environments"
    [string]$templateProgrammePath = "$TemplatesPath/programme"
    [string]$templateTeamPath = "$templateProgrammePath/team"
    [string]$templateTeamBasePath = "$templateTeamPath/base"
    [string]$templateTeamServicePath = "$templateTeamPath/service"
    [string]$templateTeamEnvironmentPath = "$templateTeamPath/environment"

    New-Directory -DirectoryPath $programmePath

    # CREATE TEAM DIRECTORIES
    foreach ($team in $teams) {
        $lookupTable['__TEAM_NAME__'] = $team.name
        $lookupTable['__SERVICE_CODE__'] = $team.servicecode

        # CREATE TEAM BASE DIRECTORIES AND FILES
        [string]$teamBaseDirectory = "$programmePath/$($team.name)/base"
        New-Directory -DirectoryPath $teamBaseDirectory
        New-Directory -DirectoryPath "$teamBaseDirectory/patch"
        Copy-Item -Path "$templateTeamBasePath/kustomization.yaml" -Destination "$teamBaseDirectory/kustomization.yaml"
        Copy-Item -Path "$templateTeamBasePath/patch/kustomization.yaml" -Destination "$teamBaseDirectory/patch/kustomization.yaml"
        ReplaceTokens -TemplateFile "$templateTeamBasePath/patch/kustomize.yaml" -DestinationFile "$teamBaseDirectory/patch/kustomize.yaml"
        ReplaceTokens -TemplateFile "$templateTeamBasePath/helm-repository.yaml" -DestinationFile "$teamBaseDirectory/helm-repository.yaml"

        # CREATE SERVICE DIRECTORIES AND FILES
        foreach ($service in $team.services) {
            New-Directory -DirectoryPath "$programmePath/$($team.name)/$($service.name)/deploy/base"
            Copy-Item -Path "$templateTeamServicePath/kustomization.yaml" -Destination $programmePath/$($team.name)/$($service.name)/kustomization.yaml
            Copy-Item -Path $templateTeamServicePath/deploy/base/* -Destination $programmePath/$($team.name)/$($service.name)/deploy/base -Recurse
    
            $lookupTable['__SERVICE_NAME__'] = $service.name
            $lookupTable['__DEPENDS_ON__'] = 'infra'

            if ($service['backend']) {
                $lookupTable['__DEPENDS_ON__'] = 'pre-deploy'
                $lookupTable['__POSTGRES_DB__'] = $service['dbname']
                New-Directory -DirectoryPath "$programmePath/$($team.name)/$($service.name)/pre-deploy/base"
                Copy-Item -Path $templateTeamServicePath/pre-deploy/base/* -Destination $programmePath/$($team.name)/$($service.name)/pre-deploy/base -Recurse
                ReplaceTokens -TemplateFile "$templateTeamServicePath/pre-deploy/base/image-repository-dbmigration.yaml" -DestinationFile "$programmePath/$($team.name)/$($service.name)/pre-deploy/base/image-repository-dbmigration.yaml"
                ReplaceTokens -TemplateFile "$templateTeamServicePath/pre-deploy/base/migration.job.yaml" -DestinationFile "$programmePath/$($team.name)/$($service.name)/pre-deploy/base/migration.job.yaml"
                ReplaceTokens -TemplateFile "$templateTeamServicePath/pre-deploy/base/post-migration-script.job.yaml" -DestinationFile "$programmePath/$($team.name)/$($service.name)/pre-deploy/base/post-migration-script.job.yaml"
                ReplaceTokens -TemplateFile "$templateTeamServicePath/pre-deploy/base/pre-migration-script.job.yaml" -DestinationFile "$programmePath/$($team.name)/$($service.name)/pre-deploy/base/pre-migration-script.job.yaml"
                ReplaceTokens -TemplateFile "$templateTeamServicePath/pre-deploy-kustomize.yaml" -DestinationFile "$programmePath/$($team.name)/$($service.name)/pre-deploy-kustomize.yaml"
                Add-Content -Path $programmePath/$($team.name)/$($service.name)/kustomization.yaml -Value "  - pre-deploy-kustomize.yaml"
            }

            ReplaceTokens -TemplateFile "$templateTeamServicePath/deploy-kustomize.yaml" -DestinationFile "$programmePath/$($team.name)/$($service.name)/deploy-kustomize.yaml"
            ReplaceTokens -TemplateFile "$templateTeamServicePath/infra-kustomize.yaml" -DestinationFile "$programmePath/$($team.name)/$($service.name)/infra-kustomize.yaml"
            ReplaceTokens -TemplateFile "$templateTeamServicePath/deploy/base/helm-release.yaml" -DestinationFile "$programmePath/$($team.name)/$($service.name)/deploy/base/helm-release.yaml"

            New-Directory -DirectoryPath "$programmePath/$($team.name)/$($service.name)/infra/base"
            Copy-Item -Path "$templateTeamServicePath/infra/base/*" -Destination $programmePath/$($team.name)/$($service.name)/infra/base -Recurse
            ReplaceTokens -TemplateFile "$templateTeamServicePath/infra/base/aso-helm-release.yaml" -DestinationFile "$programmePath/$($team.name)/$($service.name)/infra/base/aso-helm-release.yaml"
            ReplaceTokens -TemplateFile "$templateTeamServicePath/infra/base/image-repository.yaml" -DestinationFile "$programmePath/$($team.name)/$($service.name)/infra/base/image-repository.yaml"

            foreach ($environment in $team.environments) {
                $lookupTable['__ENVIRONMENT__'] = $($environment.name)
                foreach ($instance in $environment.instances) {
                    $lookupTable['__ENV_INSTANCE__'] = $instance
                    New-Directory -DirectoryPath "$programmePath/$($team.name)/$($service.name)/deploy/$($environment.name)/0$instance"
                    Copy-Item -Path $templateTeamServicePath/deploy/environment/kustomization.yaml -Destination $programmePath/$($team.name)/$($service.name)/deploy/$($environment.name)/0$instance/kustomization.yaml

                    if ($service['frontend']) {
                        ReplaceTokens -TemplateFile "$templateTeamServicePath/deploy/environment/patch-frontend.yaml" -DestinationFile "$programmePath/$($team.name)/$($service.name)/deploy/$($environment.name)/0$instance/patch.yaml"
                    }
                    else {
                        ReplaceTokens -TemplateFile "$templateTeamServicePath/deploy/environment/patch.yaml" -DestinationFile "$programmePath/$($team.name)/$($service.name)/deploy/$($environment.name)/0$instance/patch.yaml"
                    }

                    if ($service['backend']) {
                        New-Directory -DirectoryPath "$programmePath/$($team.name)/$($service.name)/pre-deploy/$($environment.name)/0$instance"
                        Copy-Item -Path $templateTeamServicePath/pre-deploy/environment/* -Destination $programmePath/$($team.name)/$($service.name)/pre-deploy/$($environment.name)/0$instance -Recurse
                        ReplaceTokens -TemplateFile "$templateTeamServicePath/pre-deploy/environment/image-policy.yaml" -DestinationFile "$programmePath/$($team.name)/$($service.name)/pre-deploy/$($environment.name)/0$instance/image-policy.yaml"
                        ReplaceTokens -TemplateFile "$templateTeamServicePath/pre-deploy/environment/migration-patch.yaml" -DestinationFile "$programmePath/$($team.name)/$($service.name)/pre-deploy/$($environment.name)/0$instance/migration-patch.yaml"
                        ReplaceTokens -TemplateFile "$templateTeamServicePath/pre-deploy/environment/kustomization.yaml" -DestinationFile "$programmePath/$($team.name)/$($service.name)/pre-deploy/$($environment.name)/0$instance/kustomization.yaml"
                        ReplaceTokens -TemplateFile "$templateTeamServicePath/pre-deploy/environment/post-migration-script-patch.yaml" -DestinationFile "$programmePath/$($team.name)/$($service.name)/pre-deploy/$($environment.name)/0$instance/post-migration-script-patch.yaml"
                        ReplaceTokens -TemplateFile "$templateTeamServicePath/pre-deploy/environment/pre-migration-script-patch.yaml" -DestinationFile "$programmePath/$($team.name)/$($service.name)/pre-deploy/$($environment.name)/0$instance/pre-migration-script-patch.yaml"
                    }

                    New-Directory -DirectoryPath $programmePath/$($team.name)/$($service.name)/infra/$($environment.name)/0$instance
                    Copy-Item -Path "$templateTeamServicePath/infra/environment/kustomization.yaml" -Destination $programmePath/$($team.name)/$($service.name)/infra/$($environment.name)/0$instance/kustomization.yaml -Recurse
                    if ($service['backend']) {
                        ReplaceTokens -TemplateFile "$templateTeamServicePath/infra/environment/patch-backend.yaml" -DestinationFile "$programmePath/$($team.name)/$($service.name)/infra/$($environment.name)/0$instance/patch.yaml"
                    }
                    else {
                        ReplaceTokens -TemplateFile "$templateTeamServicePath/infra/environment/patch.yaml" -DestinationFile "$programmePath/$($team.name)/$($service.name)/infra/$($environment.name)/0$instance/patch.yaml"
                    }
                    ReplaceTokens -TemplateFile "$templateTeamServicePath/infra/environment/image-policy.yaml" -DestinationFile "$programmePath/$($team.name)/$($service.name)/infra/$($environment.name)/0$instance/image-policy.yaml"
                }
            }
        }

        # CREATE ENVIRONMENT DIRECTORIES AND FILES
        foreach ($environment in $team.environments) {
            foreach ($instance in $environment.instances) {
                New-Directory -DirectoryPath "$programmePath/$($team.name)/$($environment.name)/0$instance"
                Copy-Item -Path "$templateTeamEnvironmentPath/*" -Destination $programmePath/$($team.name)/$($environment.name)/0$instance -Recurse
        
                foreach ($service in $team.services) {
                    $servicePathExistsInKustomization = Select-String -Path "$programmePath/$($team.name)/$($environment.name)/0$instance/kustomization.yaml" -Pattern "  - ../../$($service.name)"
                    if ($null -ne $servicePathExistsInKustomization) {
                        Write-Host 'Path exists, no need to add it'
                    }
                    else {
                        Write-Host "Adding path '  - ../../$($service.name)' to '$programmePath/$($team.name)/$($environment.name)/0$instance/kustomization.yaml'"
                        Add-Content -Path $programmePath/$($team.name)/$($environment.name)/0$instance/kustomization.yaml -Value "  - ../../$($service.name)"
                    }
                }
            }

            $pathExistsInKustomization = Select-String -Path "$environmentsPath/$($environment.name)/base/kustomization.yaml" -Pattern "  - ../../../$($programmeName)/$($team.name)/base/patch"
            if ($null -ne $pathExistsInKustomization) {
                Write-Host 'Path exists, no need to add it'
            }
            else {
                Write-Host "Adding path '  - ../../../$($programmeName)/$($team.name)/base/patch' to '$environmentsPath/$($environment.name)/base/kustomization.yaml'"
                Add-Content -Path "$environmentsPath/$($environment.name)/base/kustomization.yaml" -Value "  - ../../../$($programmeName)/$($team.name)/base/patch"
                Write-Host "Added path"
            }

            $platformPathExistsInKustomization = Select-String -Path "$environmentsPath/$($environment.name)/base/kustomization.yaml" -Pattern "  - ../../../adp-platform/kustomize.yaml"
            if ($null -ne $platformPathExistsInKustomization) {
                Write-Host 'Path exists, no need to add it'
            }
            else {
                Write-Host "Adding path '  - ../../../adp-platform/kustomize.yaml' to '$environmentsPath/$($environment.name)/base/kustomization.yaml'"
                Add-Content -Path "$environmentsPath/$($environment.name)/base/kustomization.yaml" -Value "  - ../../../adp-platform/kustomize.yaml"
                Write-Host "Added path"
            }

        }
    }

    # CREATE FEATURE BRANCH IN ADP-SERVICES-FLUX
    New-FeatureBranch -ProgrammeName $programmeName

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